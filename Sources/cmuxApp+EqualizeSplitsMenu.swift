import SwiftUI

extension cmuxApp {
    func tilePanesCommandButton() -> some View {
        splitCommandButton(title: String(localized: "command.tilePanes.title", defaultValue: "Tile Panes"), shortcut: .unbound) {
            let manager = activeTabManager
            if let workspace = manager.selectedWorkspace {
                let didTile = manager.tilePanes(tabId: workspace.id)
#if DEBUG
                if !didTile {
                    cmuxDebugLog("menu.tilePanes result=noSplitOrFailed workspaceId=\(workspace.id)")
                }
#endif
            }
        }
    }
}
