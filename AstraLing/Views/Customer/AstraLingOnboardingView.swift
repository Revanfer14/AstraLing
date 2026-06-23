//
//  AstraLingOnboardingView.swift
//  AstraLing
//
//  Created by Revan Ferdinand on 23/06/26.
//

import SwiftUI

struct AstraLingOnboardingView: View {
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
                    .init(color: Color(red: 131/255, green: 194/255, blue: 255/255).opacity(0.4), location: 0),
                    .init(color: Color(red: 238/255, green: 232/255, blue: 9/255).opacity(0.25), location: 0.45),
                    .init(color: .white, location: 0.72)
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
                                .foregroundColor(.black)
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
                                .fill(Color(red: 30/255, green: 124/255, blue: 255/255))
                                .frame(width: 30, height: 10)
                        } else {
                            Circle()
                                .fill(Color(red: 214/255, green: 233/255, blue: 255/255))
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
                        .foregroundColor(.white)
                        .frame(width: 300)
                        .padding(16)
                        .background(Color(red: 0/255, green: 69/255, blue: 229/255))
                        .cornerRadius(20)
                }
                .padding(.bottom, 44)
            }
        }
        .onAppear { hasSeenAstraLingOnboarding = true }
    }
}

#Preview {
    AstraLingOnboardingView(onStart: {})
}
