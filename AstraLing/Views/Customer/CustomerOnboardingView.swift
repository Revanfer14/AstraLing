//
//  CustomerOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct CustomerOnboardingView: View {
    let onStart: () -> Void

    private let slides: [(title: String, asset: String)] = [
        ("Temukan pedagang di sekitarmu!", "onboarding_cust_1"),
        ("Kirim Ping untuk beri tahu kamu ingin mampir.", "onboarding_cust_2"),
        ("Datangi pedagang dan lakukan pembayaran.", "onboarding_cust_3")
    ]

    @AppStorage("hasSeenAstraLingOnboarding") private var hasSeenAstraLingOnboarding = false
    @State private var selection = 0

    var body: some View {
        ZStack {
            LinearGradient(
                stops: [
                    .init(color: Color.Token.blue300.opacity(0.4), location: 0),
                    .init(color: Color.appAccent.opacity(0.25), location: 0.45),
                    .init(color: Color.appSurface, location: 0.72)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $selection) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        VStack(spacing: 40) {
                            Text(slides[index].title)
                                .font(.system(size: 28, weight: .bold))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.appTextPrimary)
                                .padding(.horizontal, 24)

                            Image(slides[index].asset)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 300)
                        }
                        .padding(.top, 20)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
                .animation(.easeInOut, value: selection)

                HStack(spacing: 5) {
                    ForEach(0..<slides.count, id: \.self) { index in
                        if index == selection {
                            Capsule()
                                .fill(Color.appTint)
                                .frame(width: 30, height: 10)
                        } else {
                            Circle()
                                .fill(Color.Token.blue100)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
                .animation(.easeInOut, value: selection)
                .padding(.top, 16)

                Spacer()

                Button {
                    onStart()
                } label: {
                    Text("Mulai jelajahi")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.appTextOnPrimary)
                        .frame(width: 300)
                        .padding(16)
                        .background(Color.appPrimary)
                        .cornerRadius(20)
                }
                .padding(.bottom, 44)
            }
        }
        .onAppear { hasSeenAstraLingOnboarding = true }
    }
}

#Preview {
    CustomerOnboardingView(onStart: {})
}
