import EventKit
import EventKitUI
import SwiftUI

struct DayView: View {

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .systemBackground
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color(white: 0) : Color(.lightGray).opacity(0.5)
    }

    @State var day: CalendarDay
    @State private var time: TimeInterval = 0
    @State private var showAllDay = false
    @State var freeTimeTapHandler: ((Date) -> Void)? = nil
    @State var eventTapHandler: ((ECEvent) -> Void)? = nil

    private var dayCapsule: some View {
        Text(dayString())
            .font(.caption)
            .padding([.top, .bottom], 6)
            .padding([.leading, .trailing], 8)
            .background(backgroundColor)
            .clipShape(Capsule())
            .padding([.top, .leading, .trailing], 8)
            .shadow(color: shadowColor, radius: 5, x: 0, y: 0)
    }

    var body: some View {
        GeometryReader { mainGeo in
            ZStack {
                GeometryReader { geometry in
                    VStack {
                        ForEach(0..<25) { hour in
                            VStack {
                                LinearGradient(
                                    gradient: .init(colors: [Color(.lightGray), .clear]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                                .frame(height: 1)
                                .opacity(0.2)
                                Spacer()
                            }
                           
                        }
                    }
                }

                GeometryReader {
                    events(with: $0)
                }
                .contentShape(Rectangle())
                .clipped()
                .onDrop(of: [.data], delegate: self)
                
                if day.date.isToday {
                    GeometryReader { geometry in
                        LinearGradient(
                            gradient: .init(colors: [.red, .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                            .frame(height: 1)
                            .offset(y: CGFloat(time) * secondHeight(for: geometry))
                    }
                }


                VStack {
                    HStack {
                        Spacer()
                        dayCapsule
                    }
                    if !day.events.filter({ $0.isAllDay }).isEmpty {
                        AllDayView(
                            events: day.events.filter { $0.isAllDay }
                        )
                        .padding([.leading, .trailing], 8)
                    }
                    Spacer()
                }
            }
            .simultaneousGesture(TapGesture().onEnded {
                
            }.sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded { value in
                let newStartTime = CGFloat((value.location.y) / secondHeight(for: mainGeo))
                let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .timeZone], from: day.date)
                let date = Calendar.current.date(from: dateComponent)!
                let s = date.addingTimeInterval(TimeInterval(newStartTime))
                let overlapsEvent = day.events.filter{s.isBetween($0.start, and: $0.end)}.count > 0
                if !overlapsEvent {
                    freeTimeTapHandler?(s)
                }
            }))
            .onAppear { startTimer() }
        }
    }

    private func events(with geometry: GeometryProxy) -> some View {
        return ForEach(day.events.filter { !$0.isAllDay }, id: \.id) { event in
            EventView(event: event, eventTapHandler: {eventTapHandler?($0)})
                .onDrag { NSItemProvider(object: DropData(dropAreaSize: geometry.size, eventIdentifier: event.id.uuidString)) }
                .offset(y: startHourOffset(for: event, with: geometry))
                .frame(
                    width: width(for: event, with: geometry),
                    height: height(for: event, with: geometry)
                )
                .offset(x: xOffset(for: event, with: geometry))
        }
    }

    private func height(for event: ECEvent, with geometry: GeometryProxy) -> CGFloat {
        let isFromPreviousDay = !event.start.isSameDay(as: day.date)
        let isToNextDay = !event.end.isSameDay(as: day.date)
        let start = isFromPreviousDay ? 0 : event.startHour.hours + event.startMinute.minutes
        let end = isToNextDay ? 2.days : event.endHour.hours + event.endMinute.minutes

        return CGFloat(end - start) * secondHeight(for: geometry)
    }

    private func width(for event: ECEvent, with geometry: GeometryProxy) -> CGFloat {
        let overlappingEvents = day.events.overlappingEvents(against: event)
        return geometry.size.width / CGFloat(overlappingEvents.count + 1)
    }

    private func xOffset(for event: ECEvent, with geometry: GeometryProxy) -> CGFloat {
        let events = day.events
            .overlappingEvents(against: event)
            .appending(event)
            .sorted()

        let index = events.firstIndex(of: event) ?? 0
        return CGFloat(index) * width(for: event, with: geometry)
    }

    private func startHourOffset(for event: ECEvent, with geometry: GeometryProxy) -> CGFloat {
        guard event.start.isSameDay(as: day.date) else {
            return 0
        }

        let start = event.startHour.hours + event.startMinute.minutes
        return CGFloat(start) * secondHeight(for: geometry)
    }

    private func secondHeight(for geometry: GeometryProxy) -> CGFloat {
        secondHeight(for: geometry.size.height)
    }

    private func secondHeight(for height: CGFloat) -> CGFloat {
        let hourHeight = height / 25
        let minuteHeight = hourHeight / 60
        return minuteHeight / 60
    }

    private func startTimer() {
        let midnightToday = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        time = Date().timeIntervalSince(midnightToday)
        let interval: TimeInterval = 1.minutes
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            time += interval
        }
    }

    private func dayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EE MMM d"
        return formatter.string(from: day.date)
    }
}

extension DayView: DropDelegate {
    func performDrop(info: DropInfo) -> Bool {
//        for item in info.itemProviders(for: [.data]) {
//            _ = item.loadObject(ofClass: DropData.self) { dropData, error in
//                guard let dropData = dropData as? DropData,
//                      let event = day.events.first(where: {$0.id.uuidString == dropData.eventIdentifier}) else { return }
//
//                let duration = event.end.timeIntervalSince1970 - event.start.timeIntervalSince1970
//
//                // seconds since 0:00
//                let newStartTime = CGFloat((info.location.y - 35) / secondHeight(for: dropData.dropAreaSize.height))
//                let roundedNewStartTime = newStartTime.roundToNearest(CGFloat(15.minutes))
//                let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .timeZone], from: day.date)
//                let date = Calendar.current.date(from: dateComponent)!
//
//                event.start = date.addingTimeInterval(TimeInterval(roundedNewStartTime))
//                event.end = event.start.addingTimeInterval(duration)
//
//                try? day.eventStore.save(event, span: .thisEvent)
//            }
//        }
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

struct DayView_Preview: PreviewProvider {

    private static var calendarDay: CalendarDay {
        var events = [ECEvent]()
        events.append(ECEvent(id: UUID(), title: "Preview event", location: "Hintonburg", start: Date(), end: Date().addingTimeInterval(1.hours), isAllDay: true))
        events.append(ECEvent(id: UUID(), title: "Interview @Apple", location: "Cupertino, CA", start: Date(), end: Date().addingTimeInterval(1.hours), isAllDay: false))
        return .init(date: Date(), events: events)
    }

    static var previews: some View {
        Group {
            DayView(day: calendarDay)
                .preferredColorScheme(.dark)
                .previewLayout(.fixed(width: 300, height: 1000))
            DayView(day: calendarDay)
                .previewLayout(.fixed(width: 300, height: 1000))
        }
    }
}
