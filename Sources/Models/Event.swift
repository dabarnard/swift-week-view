//
//  File.swift
//  
//
//  Created by Dieter Barnard on 2022/05/03.
//

import Foundation
import SwiftUI

public struct Event : Identifiable, Hashable {
    public var id: UUID
    public var title: String
    public var location: String
    public var start: Date
    public var end: Date
    public var isAllDay: Bool
    public var color: Color = Color.red
    
    public init(id: UUID,
                 title: String,
                 location: String,
                 start: Date,
                 end: Date,
                 isAllDay: Bool,
                 color: Color = Color.red) {
        self.id = id
        self.title = title
        self.location = location
        self.start = start
        self.end = end
        self.isAllDay = isAllDay
        self.color = color
    }
}

public extension Array where Element == Event {
    func overlappingEvents(against event: Event) -> Self {
        self
            .filter { !$0.isAllDay }
            .filter { someEvent in
                guard !someEvent.isAllDay, someEvent.id != event.id else { return false }
                return event.collides(with: someEvent)
            }
    }
}

public extension Event {
    private var cal: Calendar { .current }
    var startHour: Int { cal.component(.hour, from: start) }
    var startMinute: Int { cal.component(.minute, from: start) }
    var endHour: Int { cal.component(.hour, from: end) }
    var endMinute: Int { cal.component(.minute, from: end) }

    func collides(with event: Event) -> Bool {
        let startComparison = event.start.compare(start)
        let startsBeforeStart = startComparison == .orderedAscending
        let startsAfterStart = startComparison == .orderedDescending
        let startsSameStart = startComparison == .orderedSame

        let startEndComparison = event.start.compare(end)
        let startsBeforeEnd = startEndComparison == .orderedAscending
//        let startsAfterEnd = startEndComparison == .orderedDescending
//        let startsSameEnd = startEndComparison == .orderedSame

        let endStartComparison = event.end.compare(start)
//        let endsBeforeStart = endStartComparison == .orderedAscending
        let endsAfterStart = endStartComparison == .orderedDescending
//        let endSameStart = endStartComparison == .orderedSame

        let endComparison = event.end.compare(end)
        let endsBeforeEnd = endComparison == .orderedAscending
        let endsAfterEnd = endComparison == .orderedDescending
        let endsSameEnd = endComparison == .orderedSame

        let cases: [Bool] = [
            (startsBeforeStart && endsAfterStart),
            (startsBeforeEnd && endsAfterEnd),
            (startsAfterStart && endsBeforeEnd),
            (startsSameStart || endsSameEnd)
        ]

        return cases.contains { $0 }
    }
}


extension Event: Comparable {
    public static func < (lhs: Event, rhs: Event) -> Bool {
        let comparison = lhs.start.compare(rhs.start)
        guard comparison != .orderedSame else { return lhs.title < rhs.title }
        return comparison == .orderedAscending
    }
}

