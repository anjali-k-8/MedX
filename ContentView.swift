//
//  ContentView.swift
//  MedX3
//
//  Created by Anjali Priya on 5/22/24.
//

import SwiftUI

struct ContentView: View {
    @State private var medicines: [Medicine] = []
    @State private var newMedicineName: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Enter medicine name", text: $newMedicineName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addMedicine) {
                        Text("Add")
                    }
                    Button(action: removeMedicine) {
                        Text("Remove")
                    }
                    .padding(.leading)
                }
                .padding()
                
                List {
                    ForEach(medicines) { medicine in
                        NavigationLink(destination: InfoView(medicine: medicine)) {
                            MedicineRow(medicine: medicine)
                        }
                    }
                    
                }
            }
            .navigationBarTitle("Medicine List")
        }
    }

    func addMedicine() {
        guard !newMedicineName.isEmpty else { return }
        let newMedicine = Medicine(name: newMedicineName)
        medicines.append(newMedicine)
        newMedicineName = ""
    }
    
    func removeMedicine() {
        guard !medicines.isEmpty else { return }
        medicines.removeLast()
    }
}

struct MedicineRow: View {
    let medicine: Medicine
    
    var body: some View {
        HStack {
            Image(systemName: "pills")
            Text(medicine.name)
            Spacer()
            NavigationLink(destination: InfoView(medicine: medicine)) {
                EmptyView()
            }
        }
        .padding()
    }
}


struct InfoView: View {
    let medicine: Medicine
    @State private var dosage: String = ""
    @State private var value: Int = 0
    @State private var taken = Calendar.current.nextDate(after: Date(), matching: .init(hour: 8), matchingPolicy: .strict)!
    
    var body: some View {
        VStack {
            Text(medicine.name)
                .font(.title)
                .padding()

            Form {
                Section {
                    TextField("Dosage + units", text: $dosage)
                    VStack {
                        Stepper(value: $value, in: 0...10, step: 1) {
                            Text("Number of pills: \(value)") // Display the current value of the stepper
                        }
                        .padding(.vertical)
                    }
                }
                Section {
                    HStack{
                        Text("Dose Time:")
                        DatePicker("", selection: $taken, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationBarTitle("Medicine Info")
            
            CountdownTimerView(targetDate: taken)
                .padding()
        }
        .onDisappear {
            UserDefaults.standard.set(dosage, forKey: "\(medicine.id.uuidString)_dosage")
            UserDefaults.standard.set(value, forKey: "\(medicine.id.uuidString)_value")
            UserDefaults.standard.set(taken, forKey: "\(medicine.id.uuidString)_taken")
        }
        .onAppear {
            dosage = UserDefaults.standard.string(forKey: "\(medicine.id.uuidString)_dosage") ?? ""
            value = UserDefaults.standard.integer(forKey: "\(medicine.id.uuidString)_value")
            if let takenDate = UserDefaults.standard.object(forKey: "\(medicine.id.uuidString)_taken") as? Date {
                taken = takenDate
            }
            else {
                let defaultDate = Date()
                taken = defaultDate
            }
        }
    }
}

struct CountdownTimerView: View {
    let targetDate: Date
    @State private var currentTime = Date()

    var body: some View {
        VStack {
            Text("Time until next dose:")
            Text("\(timeUntilTarget())")
                .font(.title)
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            self.currentTime = Date()
        }
    }

    private func timeUntilTarget() -> String {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute, .second], from: currentTime, to: targetDate)

        var hours = components.hour ?? 0
        var minutes = components.minute ?? 0
        var seconds = components.second ?? 0

        if hours < 0 || minutes < 0 || seconds < 0 {
            // If target time has passed
            let elapsedSeconds = abs(hours * 3600 + minutes * 60 + seconds)
            if elapsedSeconds <= 60 {
                // Reset to 00:00:00 for one minute
                return "00:00:00"
            } 
            else {
                // After one minute, reset to 24 hours from the original target date
                let newTargetDate = calendar.date(byAdding: .day, value: 1, to: targetDate)!
                let newComponents = calendar.dateComponents([.hour, .minute, .second], from: currentTime, to: newTargetDate)
                hours = newComponents.hour ?? 0
                minutes = newComponents.minute ?? 0
                seconds = newComponents.second ?? 0
            }
        }

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct Medicine: Identifiable, Codable {
    var id = UUID()
    let name: String
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
