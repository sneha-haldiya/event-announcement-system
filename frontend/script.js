const API_BASE_URL = "https://hghxdtdl59.execute-api.ap-south-1.amazonaws.com"; //got this url after deployment

document.addEventListener("DOMContentLoaded", () => {
    const today = new Date().toISOString().split("T")[0];
    document.getElementById("date").setAttribute("min", today);
});

function showToast(message, duration = 3000) {
    const toast = document.getElementById("toast");
    toast.textContent = message;
    toast.classList.add("show");

    setTimeout(() => {
        toast.classList.remove("show");
    }, duration);
}

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
        showToast("Subscribed successfully!");
        document.getElementById("subscribe-form").reset();
    } else {
        showToast("Subscription failed.");
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
        showToast("Event submitted successfully!");
        document.getElementById("event-form").reset();
    } else {
        showToast("Failed to submit event.");
    }
});