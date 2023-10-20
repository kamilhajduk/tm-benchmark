[Setting name="Enable Benchmark" description="Enable or disable Benchmark Plugin" category="Settings"]
bool isPluginEnabled = true;

[Setting name="Enable Logs" description="Enable or disable Benchmark Logs" category="Settings"]
bool isLogsEnabled = false;

[Setting name="Maximum Frames" description="Maximum number of frames after Benchmark will stop" category="Settings"]
int maximumFrames = 1000000;

bool isRunning = false;
int lastStartTime = 0;
float current = 0, average = 0, minimum = 0, maximum = 0, standardDeviation = 0, summary = 0, summarySquare = 0;
int framesCount = 0;
string screenSize = "";

void Main() {
	screenSize = GetScreenSize();
}

void Update(float dt) {
	if (!isPluginEnabled) return;

	auto playground = cast<CSmArenaClient>(GetApp().CurrentPlayground);
	if (IsRaceStopped(playground)) {
		if (isRunning) {
			Stop();
			Log();
			lastStartTime = 0;
		}
		return;
	}

	auto player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
	if (player is null) return;
	
	int currentStartTime = player.StartTime;
	if (currentStartTime != lastStartTime) {
		Reset();
		Start();
		lastStartTime = currentStartTime;
	}

	if (framesCount >= maximumFrames) {
		Stop();
		Log();
	}
	
	if (isRunning) {
		CalculateFps();
	}
}

void Render() {
	if (!isPluginEnabled) return;

	UI::Begin("\\$o\\$wBenchmark", isPluginEnabled, UI::WindowFlags::AlwaysAutoResize + UI::WindowFlags::NoTitleBar + UI::WindowFlags::NoDocking);
	RenderStatistics();
	RenderButtons();
	UI::End();
}

void Start() {
	isRunning = true;
}

void Stop() {
	isRunning = false;
}

void Reset() {
	current = average = minimum = maximum = standardDeviation = summary = summarySquare = 0;
    framesCount = 0;
}

void Log() {
	if (isLogsEnabled) {
		print(
			"Average: " + tostring(int(average)) + ", " +
			"Minimum: " + tostring(int(minimum)) + ", " +
			"Maximum: " + tostring(int(maximum)) + ", " +
			"StdDeviation: " + tostring((int(standardDeviation) > 0 ? int(standardDeviation) : 0)) + ", " +
			"Total Frames: " + tostring(int(framesCount)) + ", " +
			"Screen: " + screenSize
		);
	}
}

void RenderStatistics() {
	UI::Text("Status: " + (isRunning ? "\\$0a0Running" : "\\$f00Stopped"));		
	UI::Text("Current: " + tostring(int(current)));
	UI::Text("Average: " + tostring(int(average)));
	UI::Text("Minimum: " + tostring(int(minimum)));
	UI::Text("Maximum: " + tostring(int(maximum)));
	UI::Text("StdDeviation: " + tostring((int(standardDeviation) > 0 ? int(standardDeviation) : 0)));
	UI::Text("Total Frames: " + tostring(int(framesCount)));
	UI::Text("Screen: " + screenSize);
}

void RenderButtons() {
	UI::BeginTable("buttons", 2, UI::TableFlags::SizingFixedSame);
	UI::TableNextColumn();

	if (isRunning) {
		bool stopButton = UI::ButtonColored("Stop", 0.0f, 1.0f, 1.0f);
		if (stopButton) Stop();
	} else {
		bool startButton = UI::ButtonColored("Start", 1.3f, 0.53f, 0.56f);
		if (startButton) Start();
	}

	UI::TableNextColumn();

	bool resetButton = UI::Button("Reset");
	if (resetButton) Reset();

	UI::EndTable();
}

void CalculateFps() {
	current = GetApp().Viewport.AverageFps;
	summary += current;
	summarySquare += current * current;
	framesCount++;
	average = summary / framesCount;
	if (current < minimum || minimum == 0) minimum = current;
    if (current > maximum) maximum = current;
	standardDeviation = CalculateStandardDeviation();
}

float CalculateStandardDeviation() {
	if (framesCount < 2) return 0;
	float variance = (summarySquare / framesCount) - Math::Pow(summary / framesCount, 2);
	return Math::Sqrt(variance);
}

bool IsRaceStopped(CSmArenaClient@ playground) {
	return (playground is null ||
			playground.Arena is null ||
			playground.Map is null ||
			playground.GameTerminals.Length <= 0 ||
			playground.GameTerminals[0].UISequence_Current != CGamePlaygroundUIConfig::EUISequence::Playing
	);
}

string GetScreenSize() {
	auto systemConfig = cast<CSystemConfig>(GetApp().SystemConfig);
	nat2 screenSizeFs = systemConfig.Display.ScreenSizeFS;
	return tostring(screenSizeFs.x) + "x" + tostring(screenSizeFs.y);
}