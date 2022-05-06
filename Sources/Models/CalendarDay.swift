import EventKit

public struct CalendarDay: Comparable, Identifiable, Hashable {
    
    public let id = UUID()
    public let date: Date
    public var events: [Event]

    public init(date: Date, events: [Event]) {
        self.date = date
        self.events = events
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.date < rhs.date
    }
}
