import Combine
import EventKit
import ECScrollView
import SwiftUI
import Foundation

public struct ECWeekView: View {

    @ObservedObject private var viewModel: ViewModel

    @State private var offset: CGPoint = .init(x: 1000, y: 110)
    @State private var scrollHeight: CGFloat = 500
    
    public init(viewModel: ViewModel = .init()) {
        self.viewModel = viewModel
    }

    // MARK: - Public Properties
    public var body: some View {
        GeometryReader { geometry in
            ECScrollView(.vertical, showsIndicators: false) {
                VStack {
                    ScrollViewReader { value in
                        ZStack {
                            VStack(spacing: 0){
                                ForEach(1..<25) { i in
                                    Text("")
                                        .font(.title)
                                        .frame(width: geometry.size.width ,height: geometry.size.height/CGFloat(viewModel.visibleHours))
                                        .id(i)
                                }
                                .onChange(of: viewModel.selectedIndex) { hour in
                                    print("scrolling to hour \(hour)")
                                    value.scrollTo(hour, anchor: .top)
                                }
                                Spacer()
                            }
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
                                        viewModel.horizontalContentOffsetChanged(offset, with: size, scrollViewSize: geometry.size, proxy: proxy)
                                    }
                                }
                            }
                        }
                    }
                } .frame(height: contentHeight(for: geometry))
            }
            .onContentOffsetChanged { offset, size, proxy in
                viewModel.verticalContentOffsetChanged(offset, with: size, scrollViewSize: geometry.size, proxy: proxy)
            }
            .coordinateSpace(name: "scroll")
            .frame(height: geometry.size.height)
            
        }.preferredColorScheme(.light)
    }
        
    // MARK: - Private Methods

    private func contentHeight(for geometry: GeometryProxy) -> CGFloat {
        let secondHeight = geometry.size.height / CGFloat(viewModel.visibleHours) / 60 / 60
        return secondHeight * CGFloat(24.hours)
    }
}

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

extension ECWeekView {

    public final class ViewModel: ObservableObject {

        // MARK: - Public Properties

        @Published public var visibleDays: Int
        @Published public var visibleHours: Int
        
        @Published public var days = [CalendarDay]()
        @Published public var selectedIndex = 0
        
        public var verticalOffset = 0.0
        public var daysInFuture: Int
        
        // MARK: - Private Properties

        private let calendarManager: CalendarManaging

        private var initialReferenceDate: Date

        private var horizontalContentSize = CGSize.zero
        private var horizontalScrollViewSize = CGSize.zero
        private var initialHorizontalContentLoaded = false
        
        private var verticalContentSize = CGSize.zero
        private var verticalScrollViewSize = CGSize.zero
        private var initialVerticalContentLoaded = false

        private var unselectedIndex = -100

        private var cancellables = Set<AnyCancellable>()
        

        // MARK: - Lifecycle

        public init(calendarManager: CalendarManaging = SampleCalendarManager(), visibleDays: Int = 1, visibleHours: Int = 12, daysInFuture: Int = 15) {
            print("initialising weekView")
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
                .sink { daysWithEvents in
                    self.days = daysWithEvents
                }
                .store(in: &cancellables)
        }

        // MARK: - Public Methods

        func horizontalContentOffsetChanged(_ contentOffset: CGPoint, with contentSize: CGSize, scrollViewSize: CGSize, proxy: ScrollViewProxy) {
            self.horizontalContentSize = contentSize
            self.horizontalScrollViewSize = scrollViewSize
            if !initialHorizontalContentLoaded {
                initialHorizontalContentLoaded.toggle()
                let startingDay = days[0]
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    print("initial scroll to current time")
                    proxy.scrollTo(startingDay.id, anchor: .leading)
                }
            }
        }
        
        func verticalContentOffsetChanged(_ contentOffset: CGPoint, with contentSize: CGSize, scrollViewSize: CGSize, proxy: ScrollViewProxy) {
            self.verticalContentSize = contentSize
            self.verticalScrollViewSize = scrollViewSize
            self.verticalOffset = contentOffset.y
            if self.selectedIndex != unselectedIndex{
                self.selectedIndex = unselectedIndex
            }
            if !initialVerticalContentLoaded {
                initialVerticalContentLoaded.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    let currentHour = Calendar.current.component(.hour, from: Date())
                    proxy.scrollTo(currentHour, anchor: .top)
                }
            }
        }

        func didEndDecelerating(_ contentOffset: CGPoint, scrollViewProxy: ScrollViewProxy) {
        }
        
        func eventTapped(event:ECEvent) {
            calendarManager.eventTapped(event: event)
        }
        
        func freeTimeTapped(date:Date) {
            calendarManager.freeTimeTapped(date: date)
        }
        
        public func scrollToHour(hour:Int) {
            selectedIndex = hour
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
