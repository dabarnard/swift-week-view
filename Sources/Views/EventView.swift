import EventKit
import SwiftUI

struct EventView: View {

    let event: Event
    @State  var eventTapHandler: ((Event) -> Void)? = nil
    @State private var presentEdit = false
    

    private var color: Color { event.color}

    var body: some View {
        GeometryReader { mainGeo in
            HStack(spacing: 0) {
                color
                    .frame(width: 8)
                    .opacity(0.9)
                ZStack {
                    color.opacity(0.2)
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(event.title)
                                .font(.caption)
                                .foregroundColor(color)
                                .fontWeight(.semibold)
                                .frame(alignment: .leading)
                                .padding([.top, .leading, .trailing], 8)
                                .padding([.bottom], 1)
                                .multilineTextAlignment(.leading)
                            if let location = event.location {
                                Text(location)
                                    .font(.caption2)
                                    .foregroundColor(color)
                                    .frame(alignment: .leading)
                                    .padding([.leading], 8)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                        }
                        Spacer()
                    }
                }
            }
            .foregroundColor(Color.black)
            .cornerRadius(3)
            .simultaneousGesture(TapGesture().onEnded {
                // Do something
            }.sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local).onEnded { value in
    //            let newStartTime = CGFloat((value.location.y) / secondHeight(for: mainGeo))
    //            let dateComponent = Calendar.current.dateComponents([.year, .month, .day, .timeZone], from: day.date)
    //            let date = Calendar.current.date(from: dateComponent)!
    //            let s = date.addingTimeInterval(TimeInterval(newStartTime))
                if value.location.y < mainGeo.size.height{
                    eventTapHandler?(event)
                }
            
            }))
        }
    }
}

struct EventView_Preview: PreviewProvider {

    private static var event: Event {
        let event = Event(id: UUID(), title: "Interview @Apple", location: "Cupertino, CA", start: Date(), end: Date().addingTimeInterval(1.hours), isAllDay: false)

        return event
    }

    static var previews: some View {
        EventView(event: event)
            .previewLayout(.fixed(width: 200, height: 200))
    }
}
