	document.body.innerHTML = :fw-out;
}

function :ui-add-str() {
	:ui-items.push(prompt("enter string"));
	:app-render();
}

function :ui-add-rnd() {
	:ui-items.push("" + Math.random());
	:app-render();
}

function :ui-tab(n) {
	:ui-tab = n;
	:app-render();
}

function :ui-show-panel(val) {
	:ui-show-panel = val;
	:app-render();
}
