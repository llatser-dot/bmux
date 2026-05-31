import Bonsplit
import Foundation

extension Workspace {
    func didProgrammaticallyChangeSplitGeometry() {
        splitTabBar(bonsplitController, didChangeGeometry: bonsplitController.layoutSnapshot())
    }

    @discardableResult
    func tilePanesIntoGrid() -> Bool {
        let paneGroups = orderedVisiblePanePanelGroups()
        guard paneGroups.count > 1,
              let rootPanelId = paneGroups.first?.first,
              let rootPaneId = paneId(forPanelId: rootPanelId) else {
            return false
        }

        let focusedBefore = focusedPanelId
        var targetIndex = 0
        for panelId in paneGroups.flatMap({ $0 }) {
            guard moveSurface(panelId: panelId, toPane: rootPaneId, atIndex: targetIndex, focus: false) else {
                return false
            }
            targetIndex += 1
        }

        let columns = max(1, Int(ceil(sqrt(Double(paneGroups.count)))))
        let rows = paneGroups.chunked(into: columns)
        guard tilePaneRows(rows, inPane: rootPaneId) else { return false }

        if let focusedBefore, panels[focusedBefore] != nil {
            focusPanel(focusedBefore)
        }
        didProgrammaticallyChangeSplitGeometry()
        return true
    }

    private func orderedVisiblePanePanelGroups() -> [[UUID]] {
        let paneById = Dictionary(
            uniqueKeysWithValues: bonsplitController.allPaneIds.map { ($0.id.uuidString, $0) }
        )

        return SidebarBranchOrdering
            .orderedPaneIds(tree: bonsplitController.treeSnapshot())
            .compactMap { paneIdString -> [UUID]? in
                guard let paneId = paneById[paneIdString] else { return nil }
                let panelIds = bonsplitController
                    .tabs(inPane: paneId)
                    .compactMap { panelIdFromSurfaceId($0.id) }
                    .filter { panels[$0] != nil }
                return panelIds.isEmpty ? nil : panelIds
            }
    }

    private func tilePaneRows(_ rows: [[[UUID]]], inPane paneId: PaneID) -> Bool {
        guard !rows.isEmpty else { return false }
        guard rows.count > 1 else {
            return tilePaneColumns(rows[0], inPane: paneId)
        }

        let lowerRows = Array(rows.dropFirst())
        guard let lowerPaneId = splitPaneGroups(lowerRows.flatMap { $0 }, fromPane: paneId, orientation: .vertical) else {
            return false
        }

        return tilePaneColumns(rows[0], inPane: paneId)
            && tilePaneRows(lowerRows, inPane: lowerPaneId)
    }

    private func tilePaneColumns(_ groups: [[UUID]], inPane paneId: PaneID) -> Bool {
        guard !groups.isEmpty else { return false }
        guard groups.count > 1 else { return true }

        let rightGroups = Array(groups.dropFirst())
        guard let rightPaneId = splitPaneGroups(rightGroups, fromPane: paneId, orientation: .horizontal) else {
            return false
        }

        return tilePaneColumns(rightGroups, inPane: rightPaneId)
    }

    private func splitPaneGroups(
        _ groups: [[UUID]],
        fromPane paneId: PaneID,
        orientation: SplitOrientation
    ) -> PaneID? {
        let panelIds = groups.flatMap { $0 }
        guard let seedPanelId = panelIds.first,
              let seedTabId = surfaceIdFromPanelId(seedPanelId),
              let newPaneId = bonsplitController.splitPane(
                  paneId,
                  orientation: orientation,
                  movingTab: seedTabId,
                  insertFirst: false
              ) else {
            return nil
        }

        for panelId in panelIds.dropFirst() {
            guard moveSurface(panelId: panelId, toPane: newPaneId, focus: false) else {
                return nil
            }
        }
        return newPaneId
    }
}

private extension Array {
    func chunked(into chunkSize: Int) -> [[Element]] {
        guard chunkSize > 0 else { return [self] }
        var chunks: [[Element]] = []
        var index = startIndex
        while index < endIndex {
            let end = Swift.min(self.index(index, offsetBy: chunkSize, limitedBy: endIndex) ?? endIndex, endIndex)
            chunks.append(Array(self[index..<end]))
            index = end
        }
        return chunks
    }
}
