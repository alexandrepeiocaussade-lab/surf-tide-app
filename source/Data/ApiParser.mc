using Toybox.Lang;
using Toybox.Time;
using Toybox.Time.Gregorian;

class ApiParser {

    function initialize() {}

    function parseCombinedResponse(json) {
        var results = [];

        var days = json["days"];
        if (days == null) {
            return results;
        }

        for (var i = 0; i < days.size(); i++) {
            var dayData = days[i];
            var dateStr = dayData["date"];
            var dateInfo = parseDate(dateStr);
            var dayOfWeek = getDayOfWeek(dateInfo);

            var aggregate = new DailyAggregate(dateInfo, dayOfWeek);

            var tideSection = dayData["tide"];
            if (tideSection != null) {
                var dayTide = new DayTideData(dateInfo, dayOfWeek);
                var tideEvents = tideSection["events"];
                if (tideEvents != null) {
                    for (var t = 0; t < tideEvents.size(); t++) {
                        var ev = tideEvents[t];
                        var type = (ev["type"].equals("high")) ? 1 : 0;
                        var hour = ev["hour"].toNumber();
                        var minute = ev["minute"].toNumber();
                        var height = ev["height"].toFloat();
                        var coeff = ev["coefficient"].toNumber();
                        dayTide.addEvent(new TideEvent(type, hour, minute, height, coeff));
                    }
                }
                dayTide.morningCoeff = tideSection["morningCoeff"].toNumber();
                dayTide.afternoonCoeff = tideSection["afternoonCoeff"].toNumber();
                aggregate.tide = dayTide;
            }

            var surfSection = dayData["surf"];
            if (surfSection != null) {
                var daySurf = new DaySurfData(dateInfo);
                var hours = surfSection["hours"];
                if (hours != null) {
                    for (var h = 0; h < hours.size(); h++) {
                        var hr = hours[h];
                        var surfHour = new SurfHourData();
                        surfHour.hour = hr["hour"].toNumber();
                        surfHour.waveHeight = hr["waveHeight"].toFloat();
                        surfHour.swellDirection = hr["swellDirection"];
                        surfHour.swellPeriod = hr["swellPeriod"].toNumber();
                        surfHour.windDirection = hr["windDirection"];
                        surfHour.windSpeed = hr["windSpeed"].toNumber();
                        surfHour.windGusts = hr["windGusts"].toNumber();
                        daySurf.addHourData(surfHour);
                    }
                }
                aggregate.surf = daySurf;
            }

            results.add(aggregate);
        }

        return results;
    }

    function parseDate(dateStr) {
        var parts = dateStr.split("-");
        return {
            "year" => parts[0].toNumber(),
            "month" => parts[1].toNumber(),
            "day" => parts[2].toNumber()
        };
    }

    function getDayOfWeek(dateInfo) {
        var moment = Gregorian.moment(
            dateInfo["year"],
            dateInfo["month"],
            dateInfo["day"]
        );
        var info = Gregorian.info(moment, Time.FORMAT_MEDIUM);
        return info.day_of_week;
    }
}
