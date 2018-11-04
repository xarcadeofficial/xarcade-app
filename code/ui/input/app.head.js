"use strict";

let :ui-show-panel = true;
let :ui-items = [];
let :ui-tab = 1;

function :app-render() {
let :fw-attrs = null;
let :fw-styles = null;
let :fw-out = "";
let :fw-attr(:) = function(:key, :val) {
	if(:fw-attrs == null) {
		:fw-attrs = {};
	}
	:fw-attrs[:key] = :val;
}
let :fw-style(:) = function(:key, :val) {
	if(:fw-styles == null) {
		:fw-styles = {};
	}
	:fw-styles[:key] = :val;
}
let :fw-concat(:) = function() {
	let :c = arguments.length;
	let :str = "";
	for(let :i = 0; :i < :c; :i ++) {
		:str += arguments[:i];
	}
	return :str;
}
let :fw-tag-open(:) = function(:tag) {
	:fw-out += "<" + :tag;
}
let :fw-tag-end(:) = function(:close) {
	if(:fw-attrs != null) {
		for(let :key in :fw-attrs) {
			:fw-out += " " + :key + "=\"" + :fw-attrs[:key] + "\"";
		}
		:fw-attrs = null;
	}
	if(:fw-styles != null) {
		:fw-out += " style=\"";
		for(let :key in :fw-styles) {
			:fw-out += :key + ": " + :fw-styles[:key];
		}
		:fw-out += "\"";
		:fw-styles = null;
	}
	:fw-out += ">";
}
let :fw-tag-close(:) = function(:tag) {
	:fw-out += "</" + :tag + ">";
}
let :fw-echo(:) = function(:val) {
	:fw-out += :val;
}
