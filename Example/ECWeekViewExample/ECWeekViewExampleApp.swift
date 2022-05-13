import ECWeekView
import SwiftUI
import Combine

@main
struct ECWeekViewExampleApp: App {
    
    @ObservedObject var vm = BookViewModel()
    
    var body: some Scene {
        WindowGroup {
            ECWeekView(viewModel:vm.weekView)
            DatePicker(selection: $vm.date, in: Date()...Date() + 14.days, displayedComponents: .date) {
                Text(DateFormatter.shortDateAndWeekDayFormatter.string(from: vm.date))
            }.labelsHidden()
                .onAppear{
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.seconds) {
                        vm.date = Date()
                    }
                }
        }
    }
}

class BookViewModel:ObservableObject {
    var calendarManager = SampleCalendarManager()
    var weekView : ECWeekView.ViewModel
    @Published var date : Date = Date()
    

    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.weekView = ECWeekView.ViewModel(calendarManager: calendarManager, visibleDays: 3, visibleHours: 4)
        $date.sink{ date in
            self.calendarManager.date = date
            
        }.store(in: &cancellables)
        self.calendarManager.events = []

        DispatchQueue.main.asyncAfter(deadline: .now() + 4.seconds) {
            self.calendarManager.events = [ECEvent(id: UUID(), title: "test", location: "test", start: Date() + 1.hours, end: Date() + 2.hours, isAllDay: false)]
            self.calendarManager.events = [ECEvent(id: UUID(), title: "test", location: "test", start: Date() + 1.hours, end: Date() + 2.hours, isAllDay: false)]
        }
    }
}

extension DateFormatter {
    static var shortDateAndWeekDayFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMM dd"
        return dateFormatter
    }
    
    static var shortTimeFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }
}
