import SwiftUI
import Combine

struct OverlayView: View {
    @ObservedObject var settings: SettingsManager

    @State private var currentTime = Date()
    let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }

    var body: some View {
        ZStack {
            if settings.showClockOverlay {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text(timeFormatter.string(from: currentTime))
                            .font(.system(size: 80, weight: .thin, design: .rounded))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                            .padding(60)
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut, value: settings.showClockOverlay)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
}
