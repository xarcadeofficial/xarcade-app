:fw-head();
fw-out = "<html><head><meta charset=\"UTF-8\"><title>" . fw-title .
	"</title><link rel=\"stylesheet\" type=\"text/css\" href=\"app.css\"><script src=\"app.js\"></script></head><body";
{if(fw-body-class == `null)
	fw-out .= ">";
}
{else
	fw-out .= " class=\"" . fw-body-class . "\">";
}
:fw-body();
fw-out .= "</body></html>";
~console.log(fw-out);
