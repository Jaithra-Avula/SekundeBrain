import Foundation
import SwiftUI

struct JournalDetailView: View {
    var entry: JournalEntry

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title ?? "No Title")
                    .font(.largeTitle)
                    .bold()

                Text(entry.date ?? Date(), style: .date)
                    .foregroundColor(.gray)

                if let data = entry.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                }

                Divider()

                Text(entry.content ?? "")
                    .font(.body)
                    .padding(.top, 4)

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Contents")
    }
}

