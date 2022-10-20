//
//  TutorialView.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 10/18/22.
//

import SwiftUI

// Constants
// Textos
private let kTextos = ["Bienvenidx al Museo MARCO", "Una experiencia única y llena de aprendizaje", "Conoce a la paloma MARCO"]
private let kScreenTwoText = ["¡Hola pequeñx aventurerx!", "¡Tiene que ayudarme!", "Te contaré un poco de lo que sucedió hace poco."]
private let kScreenThreeText = ["¡Unxs Aliens traviesxs vinieron al Museo Marco...", "¡E hicieron todas las obras de arte invisibles!"]
private let kScreenFourText = ["Ahora juntxs debemos de encontrarlas y devolverlas a la normalidad", "Me ayudarás a completar esta misión?"]
private let kScreenFiveText = ["Te guiaré durante el proceso para encontrar las obras de arte Invisibles", "Este dispositivo será tu rastreador, con el podrás ver las obras de arte y restaurlas"]
private let kScreenSixText = ["Si restauras todas las obras de arte se generará un código QR con una sopresa para ti"]
// Imagenes
private let kPaloma = "paloma"
private let kAlien = "alien"
private let kEstatua = "estatua"
private let kEstatuaInv = "estatuainv"
private let kArrowForward = "arrow.forward.square.fill"

struct TutorialView: View {
    
    @State var viewCounter: Int = 0
    
    var body: some View {
        switch viewCounter {
        case 0:
            ScreenOne(viewCounter: $viewCounter)
        case 1:
            ScreenTwo(viewCounter: $viewCounter)
        case 2:
            ScreenThree(viewCounter: $viewCounter)
        case 3:
            ScreenFour(viewCounter: $viewCounter)
        case 4:
            ScreenFive(viewCounter: $viewCounter)
        case 5:
            ScreenSix(viewCounter: $viewCounter)
        default:
            EmptyView()
        }
    }
    
}

// MARK: Preview
struct TutorialView_Previews: PreviewProvider {
    static var previews: some View {
        TutorialView()
    }
}

// MARK: Tutorial Views

// Screen 1
struct ScreenOne: View {
    @Binding var viewCounter: Int
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.pink.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                TextFormat(text: kTextos[0], weight: .bold)
                TextFormat(text: kTextos[1], weight: .regular)
                TextFormat(text: kTextos[2], weight: .regular)
                Spacer()
                HStack {
                    Image(kPaloma)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ButtonNext(viewCounter: $viewCounter, size: 100)
                }
                .padding(.trailing, 30.0)
                Spacer()
            }
        }
    }
}

// Screen 2
struct ScreenTwo: View {
    @Binding var viewCounter: Int
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.pink.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                TextFormatBox(text: kScreenTwoText[0]).padding(.vertical, 8)
                TextFormatBox(text: kScreenTwoText[1]).padding(.vertical, 8)
                TextFormatBox(text: kScreenTwoText[2]).padding(.vertical, 8)
                Spacer()
                HStack {
                    Image(kPaloma)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ButtonNext(viewCounter: $viewCounter, size: 100)
                }
                .padding(.trailing, 30.0)
                Spacer()
            }
        }
    }
}

// Screen 3
struct ScreenThree: View {
    @Binding var viewCounter: Int
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.pink.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                TextFormatBox(text: kScreenThreeText[0])
                    .padding(.vertical, 8)
                HStack {
                    Image(kAlien)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, -20)
                    Image(kAlien)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, -20)
                    Image(kAlien)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(.horizontal, -20)
                }.padding(.horizontal)
                TextFormatBox(text: kScreenThreeText[1])
                    .padding(.horizontal, 8)
                Spacer()
                HStack {
                    Image(kEstatuaInv)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Image(kEstatua)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ButtonNext(viewCounter: $viewCounter, size: 90)
                }
                .padding(.trailing, 30.0)
                Spacer()
            }
        }
    }
}

// Screen 4
struct ScreenFour: View {
    @Binding var viewCounter: Int
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.pink.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                TextFormatBox(text: kScreenFourText[0])
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                TextFormatBox(text: kScreenFourText[1])
                    .padding(.vertical, 8)
                Spacer()
                HStack {
                    Image(kPaloma)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ButtonNext(viewCounter: $viewCounter, size: 100)
                }
                .padding(.trailing, 30.0)
                Spacer()
            }
        }
    }
}

// Screen 5
struct ScreenFive: View {
    @Binding var viewCounter: Int
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.pink.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                TextFormatBox(text: kScreenFiveText[0])
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                TextFormatBox(text: kScreenFiveText[1])
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                Spacer()
                HStack {
                    Image(kPaloma)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ButtonNext(viewCounter: $viewCounter, size: 100)
                }
                .padding(.trailing, 30.0)
                Spacer()
            }
        }
    }
}

// Screen 6
struct ScreenSix: View {
    @Binding var viewCounter: Int
    var body: some View {
        ZStack (alignment: .bottom) {
            Color.pink.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            VStack {
                Spacer()
                TextFormatBox(text: kScreenSixText[0])
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                Spacer()
                HStack {
                    Image(kPaloma)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    ButtonNext(viewCounter: $viewCounter, size: 100)
                }
                .padding(.trailing, 30.0)
                Spacer()
            }
        }
    }
}

// MARK: Helper Views
struct TextFormat: View {
    let text: String
    let weight: Font.Weight
    var body: some View {
        Text(text)
            .font(.system(size: 30, weight: weight, design: .rounded))
            .foregroundColor(Color.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .padding(.vertical, 10)
    }
}

struct TextFormatBox: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.system(size: 25, weight: .bold, design: .rounded))
            .foregroundColor(Color.black)
            .padding(25)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 30))
            .multilineTextAlignment(.center)
    }
}

struct ButtonNext: View {
    @Binding var viewCounter: Int
    let size : CGFloat
    var body: some View {
        Button {
            viewCounter += 1
        } label: {
            Image(systemName: kArrowForward)
                .resizable()
                .frame(width: size, height: size)
                .foregroundColor(Color.white)
        }
    }
}
