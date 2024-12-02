export async function handler(event, context) {
    console.log("Hello World from the console!");

    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'text/html',
        },
        body: `<h1>Hello world!</h1>`,
    };
}