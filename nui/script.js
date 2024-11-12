const updateProgress = (pathId, percent, color) => {
    const path = document.getElementById(pathId);
    if (path) {
        percent = Math.max(0, Math.min(100, percent));
        const cx = 60, cy = 60, r = 50;
        const angle = percent * 3.6;
        const angleRadians = (angle / 180) * Math.PI;
        const x = cx + r * Math.sin(angleRadians);
        const y = cy - r * Math.cos(angleRadians);
        const largeArcFlag = angle > 180 ? 1 : 0;
        const pathData = percent === 100 ?
            `M ${cx},${cy - r} A ${r},${r} 0 1 1 ${cx},${cy + r} A ${r},${r} 0 1 1 ${cx},${cy - r}` :
            `M ${cx},${cy - r} A ${r},${r} 0 ${largeArcFlag} 1 ${x},${y}`;
        path.setAttribute('d', pathData);
        if (color) path.setAttribute('stroke', color);
    } else {
        console.error(`Invalid pathId: ${pathId}`);
    }
};

const updateBar = (barId, textId, percent) => {
    const bar = document.getElementById(barId);
    const text = document.getElementById(textId);
    if (bar && text) {
        const innerBar = bar.querySelector('.progress-inner, .veh-progress-inner');
        if (innerBar) {
            innerBar.style.width = `${percent}%`;
            text.innerText = `${percent}%`;
        }
    } else {
        console.error(`Failed to find elements with ids: ${barId}, ${textId}`);
    }
};

const updateSeatbelt = isFastened => {
    const color = isFastened ? '#FFFFFF' : '#FF0000';
    updateProgress('belt-path', 100, color);
};

const updateEngine = engineHealth => {
    let engineColor;
    if (engineHealth > 75) engineColor = '#00FF00'; // Green
    else if (engineHealth > 40) engineColor = '#FFFF00'; // Yellow
    else engineColor = '#FF0000'; // Red
    updateProgress('engine-path', 100, engineColor);
};

const updateSpeed = speed => {
    document.getElementById('speed-text').textContent = `${speed}`;
};

const toggleHUDVisibility = inVehicle => {
    document.getElementById('veh-hud').style.display = inVehicle ? 'flex' : 'none';
    document.getElementById('hud').style.left = inVehicle ? '19%' : '2%';
    document.getElementById('money-hud').style.left = inVehicle ? '19%' : '2%';
};

window.addEventListener('message', event => {
    const data = event.data;
    switch (data.type) {
        case 'updatehud':
            updateProgress('hunger-path', data.hunger);
            updateProgress('thirst-path', data.thirst);
            updateProgress('stress-path', data.stress);
            updateProgress('oxygen-path', data.oxygen);
            updateBar('health-bar', 'health-text', data.health);
            updateBar('armor-bar', 'armor-text', data.armor);
            document.getElementById('cash-text').innerText = `$${data.cash}`;
            document.getElementById('bank-text').innerText = `$${data.bank}`;
            toggleHUDVisibility(data.inVehicle);
            // Ensure speed is rounded to whole numbers
            document.getElementById('speed-text').innerText = `${Math.floor(data.speed)}`;
            document.getElementById('rpm-bar').querySelector('.veh-progress-inner').style.width = `${Math.min(data.rpm, 100)}%`;
            const petrolBar = document.getElementById('petrol-bar');
            if (petrolBar) {
                petrolBar.querySelector('.veh-progress-inner').style.width = `${Math.min(data.fuel, 100)}%`;
                document.getElementById('petrol-text').innerText = `${data.fuel.toFixed(0)}%`;
            }
            updateSeatbelt(data.belt);
            updateEngine(data.engine);
            break;
        case 'showhud':
            document.getElementById('hud').style.display = 'flex';
            break;
        case 'hidehud':
            document.getElementById('hud').style.display = 'none';
            break;
        case 'showLocationHUD':
            document.getElementById('location-hud').style.display = 'block';
            break;
        case 'hideLocationHUD':
            document.getElementById('location-hud').style.display = 'none';
            break;
        case 'updateLocation':
            document.querySelector('.direction').textContent = `${data.heading} |`;
            document.querySelector('.street').textContent = `${data.street} |`;
            document.querySelector('.city').textContent = data.area;
            break;
    }
});

