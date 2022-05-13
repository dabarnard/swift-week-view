import EventKit
import Foundation

public protocol CalendarManaging {
    func eventsFor(day date: Date, completion: (([ECEvent]) -> Void)?)
    func eventTapped(event:ECEvent)
    func freeTimeTapped(date:Date)
    var scrollPublisher: Published<Date>.Publisher { get }
    var eventsPublisher: Published<[ECEvent]>.Publisher { get }
}

public class SampleCalendarManager: CalendarManaging {
    
    @Published public var events: [ECEvent] = []
    public var eventsPublisher: Published<[ECEvent]>.Publisher { $events }
    public init() {
        
    }
    
    @Published public var date: Date = Date()
    public var scrollPublisher: Published<Date>.Publisher { $date }
    var fetchCount = 0
    
    public func eventsFor(day date: Date, completion: (([ECEvent]) -> Void)?) {
        let e = self.events.filter {$0.start.isBetween(date.startOfDay(), and: date.endOfDay())}
        completion?(e)
    }
    
    public func eventTapped(event: ECEvent) {
        print("\(event.title) starting at \(event.start) tapped")
    }
    
    public func freeTimeTapped(date: Date) {
        print(date)
        self.date = date
    }
    
    func mockEventsFor(day date:Date, count:Int = 2) -> [ECEvent] {
        var events: [ECEvent] = []
        for n in 0...count {
            events.append(
                ECEvent(
                    id: UUID(),
                    title: "Event\(n)",
                    location: "Event \(n) sub text",
                    start: date.addingTimeInterval(TimeInterval(n*1.hours)),
                    end: date.addingTimeInterval(TimeInterval(n*1.hours)).addingTimeInterval(1.hours),
                    isAllDay: false
                )
            )
        }
        return events
    }
}

extension Date {
    /// Returns the Date at the start of day (for current calendar)
    func startOfDay(in calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }
    
    /// Returns the Date at the end of day (for current calendar)
    func endOfDay(in calendar: Calendar = .current) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(in: calendar))!
    }
}
