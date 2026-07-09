// Connect IQ Phone Companion App - Surf&Tide
// This runs on the phone to handle city selection and data fetching

class SurfTideCompanion {
    constructor() {
        this.selectedCity = 'Biarritz';
        this.selectedBeach = 'Grande Plage';
        this.cities = [
            { name: 'Biarritz', lat: 43.4832, lon: -1.5588, beach: 'Grande Plage' },
            { name: 'Hossegor', lat: 43.6625, lon: -1.4447, beach: 'Plage d\'Hossegor' },
            { name: 'La Teste', lat: 44.6300, lon: -1.1483, beach: 'Plage du Penon' },
            { name: 'Biscarrosse', lat: 44.4444, lon: -1.1667, beach: 'Plage Centrale' },
            { name: 'Mimizan', lat: 44.2000, lon: -1.2333, beach: 'Plage de Mimizan' },
            { name: 'Anglet', lat: 43.4833, lon: -1.5167, beach: 'Chambre d\'Amour' },
            { name: 'Saint-Jean-de-Luz', lat: 43.3889, lon: -1.6600, beach: 'Grande Plage' }
        ];
        this.proxyUrl = 'https://surftide-proxy.example.com';
    }

    onStart(launchParams) {
        console.log('Surf&Tide Companion started');

        if (launchParams && launchParams.city) {
            this.selectedCity = launchParams.city;
        }
        if (launchParams && launchParams.beach) {
            this.selectedBeach = launchParams.beach;
        }
    }

    onStop() {
        console.log('Surf&Tide Companion stopped');
    }

    getCityList() {
        return this.cities.map(c => c.name);
    }

    selectCity(cityName) {
        const found = this.cities.find(c => c.name === cityName);
        if (found) {
            this.selectedCity = found.name;
            this.selectedBeach = found.beach;
            this.sendSettingsToWatch();
            return { success: true, city: this.selectedCity, beach: this.selectedBeach };
        }
        return { success: false, error: 'City not found' };
    }

    sendSettingsToWatch() {
        const message = {
            type: 'settings',
            city: this.selectedCity,
            beach: this.selectedBeach
        };
        // Send to watch via Communications
        if (typeof Communications !== 'undefined') {
            Communications.sendMessage(message);
        }
    }

    fetchSurfData(city, beach) {
        console.log(`Fetching surf data for ${city}, ${beach}`);

        const url = `${this.proxyUrl}/api/surf`;
        const params = {
            city: city,
            beach: beach
        };

        if (typeof Communications !== 'undefined') {
            Communications.makeWebRequest(url, params, {
                method: 'GET'
            }, (responseCode, data) => {
                if (responseCode === 200) {
                    console.log('Surf data received');
                    this.sendDataToWatch(data);
                } else {
                    console.error('Surf API error:', responseCode);
                }
            });
        }
    }

    fetchTideData(city, beach) {
        console.log(`Fetching tide data for ${city}, ${beach}`);

        const url = `${this.proxyUrl}/api/tide`;
        const params = {
            city: city,
            beach: beach
        };

        if (typeof Communications !== 'undefined') {
            Communications.makeWebRequest(url, params, {
                method: 'GET'
            }, (responseCode, data) => {
                if (responseCode === 200) {
                    console.log('Tide data received');
                    this.sendDataToWatch(data);
                } else {
                    console.error('Tide API error:', responseCode);
                }
            });
        }
    }

    fetchAllData() {
        console.log('Fetching all data');
        const url = `${this.proxyUrl}/api/combined`;
        const params = {
            city: this.selectedCity,
            beach: this.selectedBeach
        };

        if (typeof Communications !== 'undefined') {
            Communications.makeWebRequest(url, params, {
                method: 'GET'
            }, (responseCode, data) => {
                if (responseCode === 200) {
                    console.log('Combined data received');
                    this.sendDataToWatch(data);
                } else {
                    console.error('Combined API error:', responseCode);
                }
            });
        }
    }

    sendDataToWatch(data) {
        const message = {
            type: 'surf_tide_data',
            data: JSON.stringify(data)
        };

        if (typeof Communications !== 'undefined') {
            Communications.sendMessage(message);
        }
    }

    onReceiveFromWatch(message) {
        console.log('Received from watch:', JSON.stringify(message));

        if (message.type === 'request_refresh') {
            this.fetchAllData();
        } else if (message.type === 'select_city') {
            return this.selectCity(message.city);
        }
    }

    onSettingsOpen() {
        console.log('Settings opened');
        return {
            cities: this.getCityList(),
            selectedCity: this.selectedCity,
            selectedBeach: this.selectedBeach
        };
    }

    onSettingsClose(settings) {
        if (settings && settings.city) {
            this.selectCity(settings.city);
        }
    }
}

// Export for use by Connect IQ
if (typeof module !== 'undefined') {
    module.exports = SurfTideCompanion;
}
