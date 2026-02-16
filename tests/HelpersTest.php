<?php

declare(strict_types=1);

use PHPUnit\Framework\TestCase;

final class HelpersTest extends TestCase
{
    public function testTrueOrFalseMapsCommonValues(): void
    {
        $this->assertTrue(trueOrFalse('yes'));
        $this->assertTrue(trueOrFalse('Sim'));
        $this->assertFalse(trueOrFalse('no'));
        $this->assertFalse(trueOrFalse('FALSE'));
        $this->assertFalse(trueOrFalse('!YES'));
        $this->assertTrue(trueOrFalse('1'));
        $this->assertFalse(trueOrFalse('0'));
        $this->assertTrue(trueOrFalse('maybe', true));
    }

    public function testGetArgTypeParsesKeyValueFlag(): void
    {
        $result = getArgType('--speed=0.5');

        $this->assertSame('key-value', $result['type']);
        $this->assertSame('--speed', $result['key']);
        $this->assertSame('0.5', $result['value']);
    }

    public function testGetArgTypeReturnsGeneralForNonFlags(): void
    {
        $result = getArgType('hello', 1);

        $this->assertSame('general', $result['type']);
        $this->assertSame('hello', $result['value']);
        $this->assertSame(1, $result['key']);
    }

    public function testArrayMapWithKeysPreservesCustomKeys(): void
    {
        $original = ['alpha' => 'a', 'beta' => 'b'];

        $result = array_map_with_keys($original, function (string $key, string $value) {
            return [$key . '.upper' => strtoupper($value)];
        });

        $this->assertSame(['alpha.upper' => 'A', 'beta.upper' => 'B'], $result);
    }
}
