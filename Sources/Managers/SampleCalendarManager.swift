import EventKit
import Foundation

public protocol CalendarManaging {
    func eventsFor(day date: Date, completion: (([ECEvent]) -> Void)?)
    func eventTapped(event:ECEvent)
    func freeTimeTapped(date:Date)
}

public struct SampleCalendarManager: CalendarManaging {

    
    public init() {}
    
    public func eventsFor(day date: Date, completion: (([ECEvent]) -> Void)?) {
        completion?(mockEventsFor(day: date))
    }
    
    public func eventTapped(event: ECEvent) {
        print("\(event.title) starting at \(event.start) tapped")
    }
    
    public func freeTimeTapped(date: Date) {
        print(date)
    }
    
    func mockEventsFor(day date:Date, count:Int = 0) -> [ECEvent] {
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




