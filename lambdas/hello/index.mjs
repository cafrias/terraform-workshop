export async function handler(event, context) {
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'text/html',
        },
        body: `<h1>Hello world!</h1>`,
    }
}