const API_BASE_URL = ""; // this will come from terraform when backend deploys

document.getElementById("subscribe-form").addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("email").value;
    const res = await fetch(`${API_BASE_URL}/subscribe`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ email }),
    });

    if (res.ok) {
        alert("Subscribed successfully!");
    } else {
        alert("Subscription failed.");
    }
});
document.getElementById("event-form").addEventListener("submit", async (e) => {
    e.preventDefault();

    const title = document.getElementById("title").value;
    const description = document.getElementById("description").value;
    const date = document.getElementById("date").value;

    const res = await fetch(`${API_BASE_URL}/create-event`, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify({ title, description, date }),
    });

    if (res.ok) {
        alert("Event submitted successfully!");
    } else {
        alert("Failed to submit event.");
    }
});