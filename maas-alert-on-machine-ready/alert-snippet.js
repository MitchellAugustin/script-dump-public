//Paste this snippet into your inspect element console with the page of the machine you're watching open, and it will alert you when the machine is
function checkCondition() {
    const element = document.getElementsByClassName("u-nudge-left").item(0);
    if (element && element.textContent.trim() === 'Releasing') {
        (new Audio("https://oneone.augustin.tech/files/beep.mp3")).play();
        alert("Releasing!");
        clearInterval(intervalId); // Stop the interval
    }
    console.log("Polling for server release");
}

// Start polling the condition every second
const intervalId = setInterval(checkCondition, 1000);
