import EventKit
import Foundation

public protocol CalendarManaging {
    func eventsFor(day date: Date, completion: (([Event]) -> Void)?)
    func eventTapped(event:Event)
    func freeTimeTapped(date:Date)
}

public struct SampleCalendarManager: CalendarManaging {

    
    public init() {}
    
    public func eventsFor(day date: Date, completion: (([Event]) -> Void)?) {
        completion?(mockEventsFor(day: date))
    }
    
    public func eventTapped(event: Event) {
        print("\(event.title) starting at \(event.start) tapped")
    }
    
    public func freeTimeTapped(date: Date) {
        print(date)
    }
    
    func mockEventsFor(day date:Date, count:Int = 0) -> [Event] {
        var events: [Event] = []
        for n in 0...count {
            events.append(
                Event(
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




