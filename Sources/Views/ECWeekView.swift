import Combine
import EventKit
import ECScrollView
import SwiftUI

public struct ECWeekView: View {

    @ObservedObject private var viewModel: ViewModel

    @State private var offset: CGPoint = .init(x: 1000, y: 110)
    
    public init(viewModel: ViewModel = .init()) {
        self.viewModel = viewModel
    }

    // MARK: - Public Properties

    public var body: some View {
        GeometryReader { geometry in
            ScrollView(showsIndicators: false) {
                VStack {
                    Spacer()
                    HStack(spacing: 0) {
                        TimeView(visibleHours: viewModel.visibleHours)
                            .frame(width: 45)
                            .padding(.leading, 3)
                        GeometryReader { geometry in
                            ECScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 0) {
                                    ForEach(viewModel.days, id: \.id) { day in
                                        DayView(
                                            day: day,
                                            freeTimeTapHandler: { viewModel.freeTimeTapped(date: $0) },
                                            eventTapHandler: {viewModel.eventTapped(event: $0)}
                                        )
                                        .frame(width: geometry.size.width / CGFloat(viewModel.visibleDays))
                                    }
                                }
                            }
                            .didEndDecelerating { offset, proxy in
                                viewModel.didEndDecelerating(offset, scrollViewProxy: proxy)
                            }
                            .onContentOffsetChanged { offset, size, proxy in
                                viewModel.contentOffsetChanged(offset, with: size, scrollViewSize: geometry.size, scrollViewProxy: proxy)
                            }
                        }
                    }
                    .frame(height: contentHeight(for: geometry))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func contentHeight(for geometry: GeometryProxy) -> CGFloat {
        let secondHeight = geometry.size.height / CGFloat(viewModel.visibleHours) / 60 / 60
        return secondHeight * CGFloat(24.hours)
    }
}

extension ECWeekView {

    public final class ViewModel: ObservableObject {

        // MARK: - Public Properties

        @Published public var visibleDays: Int
        @Published public var visibleHours: Int
        
        @Published public var days = [CalendarDay]()
        public var daysInFuture: Int
        // MARK: - Private Properties

        private let calendarManager: CalendarManaging

        private var initialReferenceDate: Date

        private var contentSize = CGSize.zero
        private var scrollViewSize = CGSize.zero

        private var initialContentLoaded = false

        private var cancellables = Set<AnyCancellable>()

        // MARK: - Lifecycle

        public init(calendarManager: CalendarManaging = SampleCalendarManager(), visibleDays: Int = 1, visibleHours: Int = 12, daysInFuture: Int = 15) {

            self.calendarManager = calendarManager
            self.visibleDays = visibleDays
            self.visibleHours = visibleHours
            self.daysInFuture = daysInFuture

            initialReferenceDate = Calendar.current.date(bySettingHour: 0, minute: 0, second: 1, of: Date())!

            days = (0..<daysInFuture).map { day in
                let date = initialReferenceDate.advanced(by: TimeInterval(day.days))
                return CalendarDay(date: date, events: [])
            }

            fetchEvents(daysInFuture: daysInFuture)
                .sink { events in
                    self.days = events
                }
                .store(in: &cancellables)
        }

        // MARK: - Public Methods

        func contentOffsetChanged(_ contentOffset: CGPoint, with contentSize: CGSize, scrollViewSize: CGSize, scrollViewProxy: ScrollViewProxy) {
            self.contentSize = contentSize
            self.scrollViewSize = scrollViewSize
            if !initialContentLoaded {
                initialContentLoaded.toggle()
                let startingDay = days[0]
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    scrollViewProxy.scrollTo(startingDay.id, anchor: .leading)
                }
            }
        }

        func didEndDecelerating(_ contentOffset: CGPoint, scrollViewProxy: ScrollViewProxy) {
        }
        
        func eventTapped(event:Event) {
            calendarManager.eventTapped(event: event)
        }
        
        func freeTimeTapped(date:Date) {
            calendarManager.freeTimeTapped(date: date)
        }

        // MARK: - Private Methods

        private func fetchEvents(daysInFuture: Int) -> AnyPublisher<[CalendarDay], Never> {

            let days = (0..<daysInFuture)
                .map { day -> Date in
                    (initialReferenceDate).addingTimeInterval(TimeInterval(day.days))
                }
                .map { day(for: $0) }

            return Publishers
                .MergeMany(days)
                .receive(on: RunLoop.main)
                .collect()
                .map { $0.sorted() }
                .eraseToAnyPublisher()
        }

        private func day(for date: Date) -> Future<CalendarDay, Never> {
            Future() { [weak self] result in
                let _ = print(date)
                guard let self = self else { return }
                self.calendarManager.eventsFor(day: date) { events in
                    let day = CalendarDay(date: date, events: events)
                    result(.success(day))
                }
            }
        }
    }
}

struct ECWeekView_Previews: PreviewProvider {


    private static let calendarManager = SampleCalendarManager()

    private static var viewModel: ECWeekView.ViewModel {
        .init(visibleDays: 2, visibleHours: 12)
    }

    static var previews: some View {
        ECWeekView(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}
