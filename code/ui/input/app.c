+ui-show-panel = `true;
+ui-items = `array();
+ui-tab = 1;

{:ui-add-str()
	ui-items.push(~prompt("enter string"));
	:fw-render();
}

{:ui-add-rnd()
	ui-items.push("" . ~Math.random());
	:fw-render();
}

{:ui-tab(n`int)
	ui-tab = n;
	:fw-render();
}

{:ui-show-panel(val`bool)
	ui-show-panel = val;
	:fw-render();
}


{:fw-head()
	fw-title = "hey" . ui-tab;
	fw-body-class = "tab" . ui-tab;
}

{:fw-body()
	{<div>
		{<button {if(ui-tab != 1) onclick= :ui-tab"(1)"; } {else color: "blue"; } >
			"tab 1";
		}
		{<button {if(ui-tab != 2) onclick= :ui-tab"(2)"; } {else color: "blue"; } >
			"tab 2";
		}
	}
	{if(ui-tab == 1)
		"you are in tab 1";
		{if(ui-show-panel)
			{<div class= "sample-class1 sample-class2"; >
				{<button onclick= :ui-add-str"()"; >
					"add string";
				}
			}
			{each item = ui-items;
				{<div id= "div-" item; >
					{echo "- " item}
				}
			}
			{<button onclick= :ui-add-rnd"()"; >
				"add random number";
			}
		}
		{<hr>}
		{<button onclick= :ui-show-panel"(true)"; >
			{echo "show"}
		}
		{<button onclick= :ui-show-panel"(false)"; >
			{echo "hide"}
		}
	}
	{else
		"you are in tab 2";
	}
}
