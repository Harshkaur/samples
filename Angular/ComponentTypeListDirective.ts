namespace SMS.ComponentTypeList {
	"use strict";

	function ComponentListDirective(): angular.IDirective {
		return {
			replace: true,
			restrict: "E",
			template: HtmlTemplateManager.GetTemplateString(DirectiveNames.ComponentTypeList),
			scope: {
				componentListModel: "<"
			},
			controller: ControllerNames.ComponentListController,
			controllerAs: "componentListController"
		};
	}

	SolutionDesignerModule.directive(DirectiveNames.ComponentTypeList, [ComponentListDirective]);
}