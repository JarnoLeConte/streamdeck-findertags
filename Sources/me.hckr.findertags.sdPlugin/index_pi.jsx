const COLORS = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray", "Custom"];

// this is our global websocket, used to communicate from/to Stream Deck software
// and some info about our plugin, as sent by Stream Deck software
var uuid,
    actionInfo,
    appInfo,
    websocket = null;

function connectElgatoStreamDeckSocket(inPort, inUUID, inRegisterEvent, inInfo, inActionInfo) {
    uuid = inUUID;
    actionInfo = JSON.parse(inActionInfo);
    appInfo = JSON.parse(inInfo);
    websocket = new WebSocket('ws://127.0.0.1:' + inPort);

    // if connection was established, the websocket sends
    // an 'onopen' event, where we need to register our PI
    websocket.onopen = function () {
        // register property inspector to Stream Deck
        websocket.send(JSON.stringify({
            event: inRegisterEvent,
            uuid: inUUID
        }));

        // Setup DOM / initialize React
        initDOM({ settings: actionInfo.payload.settings });
    };

    websocket.onmessage = function (evt) {
        // Received message from Stream Deck
        var jsonObj = JSON.parse(evt.data);

        console.log('onMessage', jsonObj)
    };
}

// our method to pass values to the plugin
function sendValueToPlugin (value, param) {
    if (websocket && (websocket.readyState === 1)) {;
        websocket.send(JSON.stringify({
            'action': actionInfo['action'],
            'event': 'sendToPlugin',
            'context': uuid,
            'payload': {
                [param]: value
            }
        }));
    }
}

function setSettings(settings) {
    if (websocket && (websocket.readyState === 1)) {
        websocket.send(JSON.stringify({
            'event': 'setSettings',
            'context': uuid,
            'payload': settings,
        }));
    }
}


// React component for rendering the property inspector
const PI = ({ settings, setSettings }) => {
    const [tag, setTag] = React.useState(settings.tag || "");
    const [color, setColor] = React.useState(settings.color || 'Custom');

    // Persist settings once the state changes
    React.useEffect(() => {
        setSettings({ tag, color });
    }, [tag, color]);

    return (
        <div>
            <div class="sdpi-heading">CONFIGURATION</div>
            <div class="sdpi-item">
                <div
                    class="sdpi-item-label"
                    title="Configure the name of the custom tag that will be assigned to the selected files and folders in the Finder when you press the button."
                >
                    Tag
                </div>
                <input
                    class="sdpi-item-value"
                    placeholder="Tag Name"
                    value={tag}
                    onChange={e => setTag(e.target.value)}
                    required
                />
            </div>
            <div type="radio" class="sdpi-item" id="adjust_radio">
                <div class="sdpi-item-label">Color</div>
                <div class="sdpi-item-value">
                    {COLORS.map(aColor =>
                        <div class="sdpi-item-child" key={aColor}>
                            <input id={`rdio-${aColor}`} type="radio" value={aColor} name="rdio" checked={aColor === color} onChange={e => setColor(e.target.value)} />
                            <label for={`rdio-${aColor}`} class="sdpi-item-label"><span class={`tag-${aColor}`}></span></label>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

// Setup DOM with React
function initDOM({ settings }) {
    ReactDOM.render(
        <PI
            settings={settings}
            setSettings={setSettings}
        />,
        document.querySelector('.sdpi-wrapper'),
    );
}
