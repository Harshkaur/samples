namespace SMS.SideBar {
	"use strict";

	import CommonModel = SMS.Common.Models;
	import CommonServiceNames = SMS.Common.Constants.ServiceNames;
	import InjectedObjectNames = SMS.Common.Constants.InjectedObjectNames;
	import StringUtilities = SMS.Common.Utility.StringUtilities;
	import Models = SMS.SolutionDesigner.Models;

	export class SideBarService implements LayoutManager.Interfaces.ISideBarHandler {

		private componentTypeList: Array<Mscrm.Designers.SolutionDesigner.Models.ComponentItem>;

		constructor() {
		}

		public RefreshComponentTypePanel(componentTypes: Array<Models.ComponentItem>): void {
			this.componentTypeList = componentTypes;
		}

		public get ComponentTypeList(): Array<Models.ComponentItem> {
			return this.componentTypeList;
		}

	}

	SolutionDesignerModule.service(ServiceNames.SideBar, SideBarService);
};