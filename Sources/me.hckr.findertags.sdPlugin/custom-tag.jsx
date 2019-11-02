const COLORS = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple", "Gray", "Custom"];

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
                    placeholder="Custom Tag Name"
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

// Startup and render
function startup({ container, settings, setSettings }) {
    ReactDOM.render(
        <PI
            settings={settings}
            setSettings={setSettings}
        />,
        container,
    );
}