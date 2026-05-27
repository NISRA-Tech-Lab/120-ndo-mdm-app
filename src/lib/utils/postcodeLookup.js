export async function lookupPostcode(postcode) {
    
    let SDZ_name;
    let SDZ_code;
    let DZ_name;
    let DZ_code;

    const search_code = postcode.replaceAll(" ", "");

    const response = await fetch(
        "https://raw.githubusercontent.com/nisra-explore/local-stats/main/search_data/CPD_LIGHT_JULY_2024.csv"
    );
    const data = await response.text();

    const rows = data.split("\n");

    for (let row of rows) {
        const columns = row.split(",");

        if (columns[0] === search_code) {

            return {
                SDZ_code: columns[20],
                SDZ_name: columns[21],
                DZ_code: columns[18],
                DZ_name: columns[19],
            };
        }
    }

    return null; 
}
