const DEFAULT_TAGS = [
    { color: 'Red', enabled: true },
    { color: 'Orange', enabled: true },
    { color: 'Yellow', enabled: true },
    { color: 'Green', enabled: true },
    { color: 'Blue', enabled: true },
    { color: 'Purple', enabled: true },
    { color: 'Gray', enabled: true },
];

// Preload data
const colorWheelImage = new Image();
colorWheelImage.ready = false;
colorWheelImage.src = 'images/ColorWheelIcon@2x.png';
colorWheelImage.onload = () => {
    colorWheelImage.ready = true;
};


/* Helpers */

const drawTagsOnCanvas = (tags, canvas) => {
    const ctx = canvas.getContext("2d");

    const enabledTags = tags.filter((t) => t.enabled);
    const totalCount = enabledTags.length + 1;
    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const centerRadius = 50;

    // Clear previous drawing
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw colorwheel icon in the center
    if (colorWheelImage.ready) {
        ctx.drawImage(colorWheelImage, centerX - colorWheelImage.width/2, centerY - colorWheelImage.height/2);
    }

    const drawTag = (index, fillColor, strokeColor) => {
        const a = (index / totalCount) * 2 * Math.PI - (0.5 * Math.PI);
        const x = centerX + centerRadius * Math.cos(a);
        const y = centerY + centerRadius * Math.sin(a);
        const r = 13;

        ctx.fillStyle = fillColor;
        ctx.strokeStyle = strokeColor;
        ctx.lineWidth = 2

        ctx.beginPath();
        ctx.arc(x, y, r, 0, 2 * Math.PI);
        if (strokeColor) ctx.stroke();
        if (fillColor) ctx.fill();
    }

    // draw Custom tag
    drawTag(0, null, "#98989B");

    // draw Color tags
    enabledTags.forEach((tag, index) => {
        const el = document.querySelector(`.tag-${tag.color}`);
        const style = getComputedStyle(el);
        drawTag(index + 1, style.backgroundColor, null);
    });
}


/* React Components */

const SortableItem = SortableHOC.SortableElement(({ value: tag }) => (
    <li className="sortable-item" data-color={tag.color}>
        <input id={`rdio-${tag.color}`} type="radio" value={tag.color} name={`rdio-${tag.color}`} checked={tag.enabled} />
        <label for={`rdio-${tag.color}`} class="sdpi-item-label"><span class={`tag-${tag.color}`}></span></label>
    </li>
));

const SortableList = SortableHOC.SortableContainer(({ items: tags, onToggle }) => (
    <ul className="sortable-grid">
        {tags.map((tag, index) => (
            <SortableItem key={`item-${tag.color}`} index={index} value={tag} onToggle={onToggle} />
        ))}
    </ul>
));

const SortableTags = ({ tags, setTags }) => (
    <SortableList
        axis="x"
        items={tags}
        onSortEnd={({ oldIndex, newIndex }) => {
            const newTags = SortableHOC.arrayMove(tags, oldIndex, newIndex);
            const changedSorting = JSON.stringify(newTags) !== JSON.stringify(tags);

            // Toggle property 'enable' if clicked an item without sorting the list
            if (!changedSorting) {
                newTags[newIndex].enabled = !newTags[newIndex].enabled;
            }

            // Save new tags in state
            setTags(newTags);
        }}
    />
);

// React component for rendering the property inspector
const PI = ({ settings, setSettings }) => {
    const [tags, setTags] = React.useState(settings.tags || DEFAULT_TAGS);
    const canvasRef = React.useRef(null);

    // Persist settings once the state changes
    React.useEffect(() => {
        drawTagsOnCanvas(tags, canvasRef.current);
        const image = canvasRef.current.toDataURL();
        setSettings({ tags, image });
    }, [tags]);

    return (
        <div>
            <div class="sdpi-heading">CONFIGURATION</div>
            <div class="sdpi-item">
                <div
                    class="sdpi-item-label"
                    title="Determine which colors should be part of the color wheel and the order in which they appear."
                    style={{ paddingBottom: 20 }}
                >
                    Tags
                </div>
                <div class="sdpi-item-child">
                    <SortableTags tags={tags} setTags={setTags} />
                    <div style={{ justifyContent: 'center', textAlign: 'center', paddingTop: 7 }}>
                        <div>Click to toggle or drag to reorder</div>
                    </div>
                </div>
            </div>
            <canvas ref={canvasRef} width="144" height="144" style={{ display: 'none' }} />
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
