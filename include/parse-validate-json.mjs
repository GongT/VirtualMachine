import { readFileSync, writeFileSync } from 'fs';
import { dirname, resolve } from 'path';
import jsonschema from 'jsonschema';

const __dirname = dirname(new URL(import.meta.url).pathname);

function loadJson5(file) {
	const content = readFileSync(file);
	return (void 0 || eval)('let ret; ret = ' + content);
}

function die(msg) {
	console.error(msg);
	process.exit(1);
}

if (!process.argv[2]) {
	die('Required argument: path to container.json');
}
if (!process.argv[3]) {
	die('Required argument: path to output parsed json file');
}

const json = loadJson5(process.argv[2]);
const schema = loadJson5(resolve(__dirname, './container.schema.json5'));

const result = jsonschema.validate(json, schema, {allowUnknownAttributes: false, propertyName: ''});
if (result.errors && result.errors.length) {
	result.errors.forEach((e) => {
		console.error(`    "${e.property}" ${e.message}`);
	});
	die('Failed to verify json schema.');
}

delete json.$schema;
writeFileSync(process.argv[3], JSON.stringify(json), 'utf8');
