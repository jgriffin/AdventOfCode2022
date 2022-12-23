//
// Created by John Griffin on 12/22/22
//
import Algorithms

extension Day16Tests {
    typealias ValvesById = [Valve.ID: Valve]
    
    class PressureMaximizer {
        var valvesById: ValvesById
        let pressureCache = PressureCache()

        init(_ valvesById: ValvesById) {
            self.valvesById = valvesById
        }
        
        actor PressureCache {
            private var cachedPressure: [ValveState: Int] = [:]

            func get(_ state: ValveState) -> Int? {
                cachedPressure[state]
            }

            func update(_ state: ValveState, pressure: Int) {
                cachedPressure[state] = pressure
            }
        }
        
        func highestPressure(_ state: ValveState) async -> Int {
            guard state.minutesRemaining > 0 else { return 0 }
            if let pressure = await pressureCache.get(state) {
                return pressure
            }
            
            let neighbors = state.neighbors(valvesById)
            var bestNeighbor = 0
            for neighbor in neighbors {
                let pressure = await highestPressure(neighbor)
                if bestNeighbor < pressure {
                    bestNeighbor = pressure
                }
            }
            
            let pressure = state.open.reduce(bestNeighbor) { result, valve in
                result + valve.flowRate
            }
            
            await pressureCache.update(state, pressure: pressure)
            return pressure
        }
        
        func highestPressureTaskGroup(_ state: ValveState) async -> Int {
            guard state.minutesRemaining > 0 else { return 0 }
            if let pressure = await pressureCache.get(state) {
                return pressure
            }
            
            let bestNeighbor: Int = await withTaskGroup(of: Int.self) { group in
                state.neighbors(valvesById).forEach { neighbor in
                    group.addTask { await self.highestPressure(neighbor) }
                }
                return await group.max() ?? 0
            }
            
            let pressure = state.open.reduce(bestNeighbor) { result, valve in
                result + valve.flowRate
            }
            
            await pressureCache.update(state, pressure: pressure)
            return pressure
        }
    }
    
    struct ValveState: Hashable {
        let minutesRemaining: Int
        let open: Set<Valve>
        let current: Valve
        let current2: Valve?

        // MARK: - neighbors

        func neighbors(_ valvesById: ValvesById) -> [ValveState] {
            guard minutesRemaining > 0 else { return [] }

            let currentActions = currentActions(valvesById)
            
            guard let current2Actions = current2Actions(valvesById) else {
                return currentActions.compactMap { afterActions($0, action2: nil) }
            }
            
            return product(currentActions, current2Actions).compactMap {
                afterActions($0.0, action2: $0.1)
            }
        }

        // MARK: - actions
        
        enum Action {
            case openValve
            case moveTo(Valve)
        }

        func currentActions(_ valvesById: ValvesById) -> [Action] {
            var actions: [Action] = current.leadsTo.map { .moveTo(valvesById[$0]!) }
            if !open.contains(current) {
                actions.append(.openValve)
            }
            return actions
        }
        
        func current2Actions(_ valvesById: ValvesById) -> [Action]? {
            guard let current2 = current2 else { return nil }
            var actions: [Action] = current2.leadsTo.map { .moveTo(valvesById[$0]!) }
            if !open.contains(current2) {
                actions.append(.openValve)
            }
            return actions
        }
        
        func afterActions(_ action: Action, action2: Action?) -> ValveState? {
            var newCurrent = current
            var newOpen = open
            
            switch action {
            case .openValve:
                if !newOpen.insert(current).inserted {
                    return nil
                }
            case let .moveTo(valve):
                newCurrent = valve
            }
            
            guard var newCurrent2 = current2 else {
                return .init(
                    minutesRemaining: minutesRemaining - 1,
                    open: newOpen,
                    current: newCurrent,
                    current2: nil
                )
            }
            
            switch action2 {
            case nil: break
            case .openValve:
                if !newOpen.insert(newCurrent2).inserted {
                    return nil
                }
            case let .moveTo(valve):
                newCurrent2 = valve
            }
            
            // pick an order to reduce branching
            if newCurrent.id > newCurrent2.id {
                (newCurrent, newCurrent2) = (newCurrent2, newCurrent)
            }
            
            return .init(
                minutesRemaining: minutesRemaining - 1,
                open: newOpen,
                current: newCurrent,
                current2: newCurrent2
            )
        }
    }
}
