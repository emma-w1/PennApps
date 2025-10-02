# Sollis 
https://docs.google.com/presentation/d/1kRaQyKPKHA3sn7sRTVwOSdsWiQJeeMlTRAeg5QPmgUQ/edit?usp=sharing (see the hardware slide for specifics)

![IMG_1729](https://github.com/user-attachments/assets/9387e392-cb59-408f-9fe3-b016843df017)
![IMG_1762](https://github.com/user-attachments/assets/7fb1ea00-e989-4e8d-9cf9-fccb47788dfd)
<img width="1920" height="1080" alt="Screenshot 2025-10-02 at 3 26 41 PM (2)" src="https://github.com/user-attachments/assets/f462e841-c07a-4627-ad78-d3d46481a791" />


A wearable armband and iOS app that helps you track UV exposure in real time and receive personalized sun safety recommendations.

## Inspiration
Too much sun exposure is the leading preventable cause of skin cancer, but most people don’t realize when they’re at risk. We wanted to create a simple, wearable way to monitor UV exposure and make sun safety more accessible—especially across different skin tones.

## What It Does
Sollis is a wearable + mobile system that:
- Uses a UV sensor to measure sunlight intensity.
- Processes data in a backend to calculate a risk score.
- Leverages Cerebras AI to generate personalized insights (e.g., when to reapply sunscreen or step into the shade).
- Displays results in a Swift-based iOS app with actionable guidance.

## How We Built It
Hardware: Arduino board + UV sensor programmed in C++ to capture exposure data.
Backend: Python service that processes UV readings, calculates risk, and communicates with the Cerebras API.
Mobile App: An iOS app written in Swift to visualize exposure data and deliver recommendations.
Database & Cloud: Firebase + GitHub integration for data handling and collaboration.

## Challenges We Ran Into
* Compiling issues while integrating Arduino code into the broader system.
* Designing a UV-to-risk formula that was both accurate and meaningful.
* Getting each layer of the stack (hardware → backend → AI → app) to communicate reliably under hackathon time constraints.

## Accomplishments We’re Proud Of
* Built a full-stack prototype in under 36 hours.
* Successfully integrated hardware, backend logic, AI inference, and mobile UI into a working system.
* Created a user-friendly experience that turns raw sensor data into clear, actionable insights.

## What We Learned
* How to connect hardware, backend, and frontend into a cohesive system.
* Debugging integration issues under tight deadlines.
* Refining formulas for real-world health accuracy.
* How AI can make technical health data feel personal and actionable.

## What’s Next for Sollis
* Sleeker, more comfortable wearable design.
* Better sensor calibration for improved accuracy.
* Expanded inclusivity by tailoring recommendations across a wider range of skin tones.

## Built With and BY
Arduino, C++, Cerebras, Firebase, GitHub, Python, Swift
By: Emma Wong, Adishree Das, Vijeta Garg, & Skyler Hall

[![Athena Award Badge](https://img.shields.io/endpoint?url=https%3A%2F%2Faward.athena.hackclub.com%2Fapi%2Fbadge)](https://award.athena.hackclub.com?utm_source=readme)
