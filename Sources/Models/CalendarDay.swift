import EventKit

public struct CalendarDay: Comparable, Identifiable, Hashable {
    
    public let id = UUID()
    public let date: Date
    public var events: [ECEvent]

    public init(date: Date, events: [ECEvent]) {
        self.date = date
        self.events = events
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }
}
