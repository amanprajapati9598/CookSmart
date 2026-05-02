const fs = require('fs');
const https = require('https');

const mermaidCode = `graph LR
    User[User]

    subgraph Processes
        direction TB
        P1((1.0<br/>Authentication))
        P2((2.0<br/>Recipe Search<br/>& View))
        P3((3.0<br/>Community<br/>Feed))
        P4((4.0<br/>Pantry<br/>Tracking))
        P5((5.0<br/>Dashboard<br/>Management))
        
        %% Down arrows connecting circles
        P1 --> P2
        P2 --> P3
        P3 --> P4
        P4 --> P5
    end

    D2[(D2 User DB)]
    D3[(D3 Recipe DB)]
    D4[(D4 Feed DB)]
    D5[(D5 Ingredient DB)]
    D6[(D6 Bookmark DB)]

    %% Connections between User and Processes
    User -- Login Info --> P1
    P1 -- Verification --> User

    User -- Search Queries --> P2
    P2 -- Recipe Details / Results --> User

    User -- Post Content --> P3
    P3 -- Feed / Post Updates --> User

    User -- Inventory Updates --> P4
    P4 -- Inventory Status --> User

    User -- Request Stats --> P5
    P5 -- Profile Statistics / Analytics --> User

    %% Connections between Processes and Data Stores
    P1 <--> D2
    P2 <--> D3
    P3 <--> D4
    P4 <--> D5
    P5 <--> D6
    P5 <--> D3
`;

const data = JSON.stringify({
  diagram_source: mermaidCode
});

const options = {
  hostname: 'kroki.io',
  path: '/mermaid/png',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(data)
  }
};

const req = https.request(options, (res) => {
  if (res.statusCode === 200) {
    const file = fs.createWriteStream('dfd_updated.png');
    res.pipe(file);
    file.on('finish', () => {
      file.close();
      console.log('Successfully created dfd_updated.png');
    });
  } else {
    console.error('Failed with status code: ' + res.statusCode);
  }
});

req.on('error', (e) => {
  console.error('Error: ' + e.message);
});

req.write(data);
req.end();
