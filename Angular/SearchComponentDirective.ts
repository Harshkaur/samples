

namespace SMS.SearchComponent {
	"use strict";

	function SearchComponentDirective(): angular.IDirective {
		return {
			replace: true,
			restrict: "E",
			template: HtmlTemplateManager.GetTemplateString(DirectiveNames.SearchComponent)
		};
	}

	SolutionDesignerModule.directive(DirectiveNames.SearchComponent, [SearchComponentDirective]);
}