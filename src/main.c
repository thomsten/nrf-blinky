/* Standard libraries */
#include <stdint.h>
#include <stddef.h>

/* SDK headers */
#include <nrf_delay.h>
#include <app_error.h>
#include <app_simple_timer.h>

#include <boards.h>

static void gpio_init(void)
{
    NRF_GPIO->DIRSET = LEDS_MASK;
    NRF_GPIO->OUT    = LEDS_MASK;
}

static void blink(uint32_t led, uint32_t repeats)
{
    NRF_GPIO->OUTSET = (1 << led);
    for (uint32_t i = 0; i < repeats; ++i)
    {
        NRF_GPIO->OUTCLR = (1 << led);
        nrf_delay_ms(50);
        NRF_GPIO->OUTSET = (1 << led);
        nrf_delay_ms(50);
    }
}

void app_error_handler(uint32_t error_code, uint32_t line_number, const uint8_t * filename)
{
    while(true)
    {
        blink(LED_RGB_RED, 1);
    }
}

static void timer_handler(void * unused)
{
    blink(LED_RGB_GREEN, 5);
}

int main(void)
{
    uint32_t status;

    gpio_init();

    status = app_simple_timer_init();
    APP_ERROR_CHECK(status);

    status = app_simple_timer_start(APP_SIMPLE_TIMER_MODE_REPEATED,
                                    timer_handler,
                                    65000,
                                    NULL);
    APP_ERROR_CHECK(status);

    while (1)
    {
        __WFI();
    }
}
