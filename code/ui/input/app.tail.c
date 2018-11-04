{:fw-render()
	:fw-head();
	~document~title = fw-title;
	fw-out = "";
	~document~body~className = fw-body-class;
	:fw-body();
	~document~body~innerHTML = fw-out;
}
