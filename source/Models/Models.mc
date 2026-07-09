using Toybox.Lang;
using Toybox.Time;

enum WindStrength {
    WIND_LIGHT = 0,
    WIND_MODERATE = 1,
    WIND_STRONG = 2
}

class TideEvent {
    var type;
    var hour;
    var minute;
    var height;
    var coefficient;

    function initialize(type_, hour_, minute_, height_, coeff_) {
        type = type_;
        hour = hour_;
        minute = minute_;
        height = height_;
        coefficient = coeff_;
    }

    function getLabel() {
        if (type == 0) {
            return "BM";
        }
        return "PM";
    }

    function getTimeString() {
        return Lang.format("$1$:$2$", [hour.format("%02d"), minute.format("%02d")]);
    }
}

class DayTideData {
    var date;
    var dayOfWeek;
    var events;
    var morningCoeff;
    var afternoonCoeff;

    function initialize(date_, dayOfWeek_) {
        date = date_;
        dayOfWeek = dayOfWeek_;
        events = [];
        morningCoeff = 0;
        afternoonCoeff = 0;
    }

    function addEvent(event) {
        events.add(event);
    }
}

class SurfHourData {
    var hour;
    var waveHeight;
    var swellDirection;
    var swellPeriod;
    var windDirection;
    var windSpeed;
    var windGusts;

    function initialize() {
        hour = 0;
        waveHeight = 0.0f;
        swellDirection = "N";
        swellPeriod = 0;
        windDirection = "N";
        windSpeed = 0;
        windGusts = 0;
    }
}

class DaySurfData {
    var date;
    var hourlyData;
    var averageWaveHeight;

    function initialize(date_) {
        date = date_;
        hourlyData = [];
        averageWaveHeight = 0.0f;
    }

    function addHourData(data) {
        hourlyData.add(data);
        recalcAverage();
    }

    function recalcAverage() {
        var total = 0.0f;
        var count = 0;
        for (var i = 0; i < hourlyData.size(); i++) {
            var d = hourlyData[i];
            if (d.waveHeight > 0.0f) {
                total += d.waveHeight;
                count++;
            }
        }
        if (count > 0) {
            averageWaveHeight = total / count;
        }
    }
}

class DailyAggregate {
    var date;
    var dayLabel;
    var tide;
    var surf;

    function initialize(date_, dayLabel_) {
        date = date_;
        dayLabel = dayLabel_;
    }

    function getNextTideEvent(currentTime) {
        if (tide == null) {
            return null;
        }
        var next = null;
        for (var i = 0; i < tide.events.size(); i++) {
            var event = tide.events[i];
            var eventMinutes = event.hour * 60 + event.minute;
            var nowMinutes = currentTime.hour * 60 + currentTime.min;
            if (eventMinutes > nowMinutes) {
                if (next == null || eventMinutes < (next.hour * 60 + next.minute)) {
                    next = event;
                }
            }
        }
        return next;
    }

    function getWindStrengthLabel(speed) {
        if (speed >= 25) {
            return WIND_STRONG;
        } else if (speed >= 10) {
            return WIND_MODERATE;
        }
        return WIND_LIGHT;
    }
}

class GeoLocation {
    var lat;
    var lon;
    var name;

    function initialize(lat_, lon_, name_) {
        lat = lat_;
        lon = lon_;
        name = name_;
    }
}

class AppSettings {
    var selectedCity;
    var selectedBeach;
    var refreshIntervalMinutes;
    var unitsMetric;

    function initialize() {
        selectedCity = "Biarritz";
        selectedBeach = "Grande Plage";
        refreshIntervalMinutes = 60;
        unitsMetric = true;
    }
}
