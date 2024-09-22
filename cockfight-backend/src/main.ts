import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

/**
 * @author Jayendra Madara
 * @version 1.0
 * @since 2023-3-20
 * Init of Out APP
 * > well i am using global piplines to validate icomming request Body with the help of typescript
 *
 */
async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  /**
   * global pipes parse incoming body to my controllers before hand and extract data params according to typescript   definitions i provided
   * I was also using class-validator and class-transformer for support
   */
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
    }),
  );
  /**
   * PORT num assigned by railway itself
   */
  await app.listen(process.env.PORT || 3333);
}
bootstrap();
// npx @compodoc/compodoc -p tsconfig.json -s
