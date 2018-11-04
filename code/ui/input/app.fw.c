+fw-title = "";
+fw-body-class = `null;
+fw-attrs = `null;
+fw-styles = `null;
+fw-out = `null;

{:fw-attr(key`str, val`str)
	{if(fw-attrs == `null)
		fw-attrs = `object();
	}
	fw-attrs[key] = val;
}

{:fw-style(key`str, val`str)
	{if(fw-styles == `null)
		fw-styles = `object();
	}
	fw-styles[key] = val;
}

{:fw-concat()
	+str = "";
	{each a = ~arguments;
		str .= a;
	}
	{return str}
}

{:fw-tag-open(tag`str)
	fw-out .= "<" . tag;
}

{:fw-tag-end(close`bool)
	{if(fw-attrs != `null)
		{map key = fw-attrs;
			fw-out .= " " . key . "=\"" . fw-attrs[key] . "\"";
		}
		fw-attrs = `null;
	}
	{if(fw-styles != `null)
		fw-out .= " style=\"";
		{map key = fw-styles;
			fw-out .= key . ": " . fw-styles[key];
		}
		fw-out .= "\"";
		fw-styles = `null;
	}
	fw-out .= ">";
}

{:fw-tag-close(tag`str)
	fw-out .= "</" . tag . ">";
}

{:fw-echo(val`str)
	fw-out .= val;
}
