import EventKit
import SwiftUI

struct AllDayEventView: View {

    let event: ECEvent

    @State private var presentEditEvent = false

    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .systemBackground
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color(white: 0) : Color(.lightGray).opacity(0.5)
    }

    private var eventColor: Color {
        event.color
    }

    var body: some View {
        Text(event.title)
            .font(.caption)
            .padding(5)
            .foregroundColor(eventColor)
            .cornerRadius(2)
            .frame(maxWidth: .infinity)
            .background(eventColor.opacity(0.2))
            .onTapGesture { presentEditEvent.toggle() }
//            .sheet(isPresented: $presentEditEvent) {
//                EventEditView(event: event, eventStore: eventStore)
//            }
    }
}

struct AllDayView: View {

    let events: [ECEvent]

    @State private var show = false
    @Environment(\.colorScheme) private var colorScheme

    private var backgroundColor: Color {
        colorScheme == .dark ? Color(white: 0.1) : .systemBackground
    }

    private var shadowColor: Color {
        colorScheme == .dark ? Color(white: 0) : Color(.lightGray).opacity(0.5)
    }

    var body: some View {
        VStack {
//            if show {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(events) { AllDayEventView(event: $0) }
                }
                .padding(2)
                .background(backgroundColor)
                .shadow(color: shadowColor, radius: 5, x: 0, y: 0)
//            }

            HStack {
                Spacer()

                HStack {
//                    if show {
                        Text("All day")
                            .font(.caption)
//                    }
//                    Image(systemName: "chevron.\(show ? "up" : "down")")
//                        .font(.caption)
                }
                .padding([.top, .bottom], 6)
                .padding([.leading, .trailing], 8)
                .background(backgroundColor)
                .clipShape(Capsule())
                .shadow(color: shadowColor, radius: 5, x: 0, y: 0)
//                .onTapGesture {
//                    show.toggle()
//                }
            }
            Spacer()
        }
    }
}

struct AllDayView_Previews: PreviewProvider {

    private static var event: ECEvent {
        let event = ECEvent(id: UUID(), title: "Preview event", location: "Hintonburg", start: Date(), end: Date().addingTimeInterval(1.hours), isAllDay: true)
        return event
    }

    static var previews: some View {
        AllDayView(events: [event, event, event])
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 500, height: 300))
            .previewDevice(nil)
    }
}
