import ECWeekView
import SwiftUI
import EventKit

@main
struct ECWeekViewExampleApp: App {
    let vm = ECWeekView.ViewModel(calendarManager: SampleCalendarManager(), visibleDays: 3, visibleHours: 4)
    var body: some Scene {
        WindowGroup {
            
            ECWeekView(viewModel:vm)
        }
        
    }
}
