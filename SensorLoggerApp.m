%Marko Tyhansky
%This is my first independent MATLAB project and experimentation with
%Arduino and sensor technology

classdef SensorLoggerApp < matlab.apps.AppBase

    % Properties store UI components which will be used in application
    % interface
    properties (Access = public)
        UIFigure          matlab.ui.Figure
        StartButton       matlab.ui.control.Button
        StopButton        matlab.ui.control.Button
        IntervalField     matlab.ui.control.NumericEditField
        IntervalLabel     matlab.ui.control.Label
        StatusLabel       matlab.ui.control.Label
        SensorValueText   matlab.ui.control.TextArea
        UIAxes            matlab.ui.control.UIAxes
    end
    
    %These properties private, meaning they will hold the
    % raw data we collect
    properties (Access = private)
        SerialObj         % Serial port object
        TimerObj          % Timer object for scheduled logging
        SensorPlot        % Line object for real-time plotting
        DataLog           % Data table for storing sensor values
    end

    % These methods initialize the app and determine the starting
    %values/functions when the app is run
    methods (Access = private)

        function startupFcn(app)
            % Initialize serial connection
            app.SerialObj = serialport("COM3", 9600); % Change COM number based on input source
            configureTerminator(app.SerialObj, "LF");

            % Sets up sensor plot with labels
            app.SensorPlot = animatedline(app.UIAxes, 'Color', 'b', 'LineWidth', 2);
            xlabel(app.UIAxes, "Time");
            ylabel(app.UIAxes, "Sensor Value");
            title(app.UIAxes, "Real-Time Sensor Data");

            app.DataLog = table(datetime, double([]), 'VariableNames', {'Timestamp', 'SensorValue'});

            % Sets initialized status
            app.StatusLabel.Text = "Status: Ready";
        end

        function readSensorData(app)
            % Reads data from the sensor and assigns it to proper objects
            try
                rawData = readline(app.SerialObj);
                sensorValue = str2double(rawData);
                
                % Update GUI elements based on collected data
                timestamp = datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss');
                app.SensorValueText.Value = sprintf("Latest Value: %.2f", sensorValue);
                addpoints(app.SensorPlot, datenum(timestamp), sensorValue);
                datetick(app.UIAxes, 'x', 'HH:MM:SS');
                drawnow;

                % Uodate data to table and present information
                newData = table(timestamp, sensorValue);
                app.DataLog = [app.DataLog; newData];

                % Saves data to Excel
                writetable(app.DataLog, "SensorLog.xlsx", "WriteMode", "append");
                
            catch
                warning("Error reading from sensor.");
            end
        end
        
        function startLogging(app, ~)
            % Function used in UI that allows user to start collecting data
            app.StatusLabel.Text = "Status: Logging...";
            app.TimerObj = timer('ExecutionMode', 'fixedRate', ...
                'Period', app.IntervalField.Value, ...
                'TimerFcn', @(~, ~) readSensorData(app));
            start(app.TimerObj);
        end

        function stopLogging(app, ~)
            % Opposite of previous function, stops collecting data
            app.StatusLabel.Text = "Status: Stopped";
            stop(app.TimerObj);
            delete(app.TimerObj);
        end
    end

    % Creates UI elements that the user will see when running app
    methods (Access = private)

        function createComponents(app)
            % The following are the visible buttons/components of the
            %graphical user interface
            app.UIFigure = uifigure('Position', [100, 100, 600, 400]);
            app.StartButton = uibutton(app.UIFigure, 'push', ...
                'Position', [50, 350, 100, 30], ...
                'Text', 'Start Logging', ...
                'ButtonPushedFcn', @(btn, event) startLogging(app));

            app.StopButton = uibutton(app.UIFigure, 'push', ...
                'Position', [200, 350, 100, 30], ...
                'Text', 'Stop Logging', ...
                'ButtonPushedFcn', @(btn, event) stopLogging(app));

            app.IntervalLabel = uilabel(app.UIFigure, ...
                'Position', [50, 300, 120, 30], ...
                'Text', 'Logging Interval (s):');

            app.IntervalField = uieditfield(app.UIFigure, 'numeric', ...
                'Position', [180, 305, 50, 25], ...
                'Value', 1);

            app.StatusLabel = uilabel(app.UIFigure, ...
                'Position', [50, 270, 200, 30], ...
                'Text', 'Status: Ready');

            app.SensorValueText = uitextarea(app.UIFigure, ...
                'Position', [50, 230, 200, 30], ...
                'Value', 'Latest Value: --');

            app.UIAxes = uiaxes(app.UIFigure, ...
                'Position', [50, 50, 500, 150]);
        end
    end

    % Constructs the app and allows user to start it
    methods (Access = public)

        function app = SensorLoggerApp()
            createComponents(app);
            startupFcn(app);
        end
    end
end