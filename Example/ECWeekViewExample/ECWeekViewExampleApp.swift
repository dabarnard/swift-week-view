import ECWeekView
import SwiftUI
import EventKit

@main
struct ECWeekViewExampleApp: App {

    var body: some Scene {
        WindowGroup {
            ECWeekView(viewModel:ECWeekView.ViewModel(calendarManager: SampleCalendarManager(), visibleDays: 3, visibleHours: 12))
        }
        
    }
}
