//
//  CardView.swift
//  TutorialMarco
//
//  Created by Alumno on 29/11/22.
//

import SwiftUI

struct CardView: View {
    let card: Card
    var removal: (() -> Void)? = nil

    @State private var isShowingAnswer = false
    @State private var offset = CGSize.zero
    
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    var body: some View {
        if(horizontalSizeClass == .compact){
            iPhoneView
        } else {
            iPadView
        }
    }
}

struct CardView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(card: Card.example)
    }
}

extension CardView {
    var iPhoneView: some View {

        GeometryReader { proxy in
            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color("lightPink")).shadow(radius: 10)
                    VStack {
                        
                        Image(card.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 150)
                            .padding(.top, 40)
                        
                        VStack(alignment: .leading) {
                            Text(card.title)
                                .font(.title2).bold()
                                .foregroundColor(.black)
                                .padding(.top, 3)
                            Text(card.descripcion)
                                .font(.headline)
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .padding(.top, 3)
                        }
                        .padding()
                        .padding(.bottom, 10)
                        
                    }
                    .padding()
                }
                .frame(width: proxy.size.width*0.75, height: proxy.size.height*0.60)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onTapGesture {
                isShowingAnswer.toggle()
            }
            .rotationEffect(.degrees(Double(offset.width / 5)))
            .offset(x: offset.width * 5, y: 0)
            .opacity(2 - Double(abs(offset.width / 50)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { _ in
                        if abs(offset.width) > 100 {
                            removal?()
                        } else {
                            offset = .zero
                        }
                    }
            )
        }
    }
    
    var iPadView: some View {

        GeometryReader { proxy in
            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 25, style: .continuous)
                        .fill(Color("lightPink")).shadow(radius: 10)
                    VStack(spacing: 0) {
                        
                        Image(card.image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 270)
                            .padding(.top, 40)
                        VStack(alignment: .leading) {
                            Text(card.title)
                                .font(.title).bold()
                                .foregroundColor(.black)
                            Text(card.descripcion)
                                .font(.title2)
                                .fontWeight(.light)
                                .foregroundColor(.black)
                                .padding(.top, 3)
                        }
                        .frame(width: proxy.size.width/3, height: proxy.size.height/6)
                    }
                    .padding(.top, 0)
                    .padding(.bottom, 40)
                }
                .frame(width: proxy.size.width*0.50, height: proxy.size.height*0.5)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onTapGesture {
                isShowingAnswer.toggle()
            }
            .rotationEffect(.degrees(Double(offset.width / 5)))
            .offset(x: offset.width * 5, y: 0)
            .opacity(2 - Double(abs(offset.width / 50)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                    }
                    .onEnded { _ in
                        if abs(offset.width) > 100 {
                            removal?()
                        } else {
                            offset = .zero
                        }
                    }
            )
        }
    }
}
